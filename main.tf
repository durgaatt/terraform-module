resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support = var.enable_dns_support
  tags = merge(var.common_tags,
  {
    Name = "${var.project_name}_vpc"
  }
  )
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.common_tags,
  {
    Name = "${var.project_name}_gw"
  }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)
  vpc_id     = aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = local.az[count.index]

  tags = merge(var.common_tags,
   {
    Name = "${var.project_name}_public_${local.az[count.index]}"
   }
   )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr[count.index]
  availability_zone = local.az[count.index]

  tags = merge(var.common_tags,
   {
    Name = "${var.project_name}_private_${local.az[count.index]}"
   }
   )
}

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidr[count.index]
  availability_zone = local.az[count.index]

  tags = merge(var.common_tags,
   {
    Name = "${var.project_name}_database_${local.az[count.index]}"
   }
   )
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = merge(var.common_tags,
  {
  Name = "${var.project_name}_public_rt"
  }
  )
}

resource "aws_eip" "eip" {
  domain   = "vpc"
  tags = merge(var.common_tags,
  {
    Name = "${var.project_name}_eip"
  })
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id
    tags = merge(var.common_tags,
    {
    Name = "${var.project_name}_nat_gw"
    }
    )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.nat_gw.id
  }
  
  tags = merge(var.common_tags,
  {
  Name = "${var.project_name}_private_rt"
  }
  )
}

resource "aws_route_table" "database_rt" {
  vpc_id = aws_vpc.main.id
 route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.nat_gw.id
 }
 
  tags = merge(var.common_tags,
  {
  Name = "${var.project_name}_database_rt"
  }
  )
}

resource "aws_route_table_association" "public_rt_assoc" {
  count = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id

}

resource "aws_route_table_association" "private_rt_assoc" {
  count = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id

}

resource "aws_route_table_association" "database_rt_assoc" {
  count = length(aws_subnet.database)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database_rt.id

}

resource "aws_db_subnet_group" "database_sub_grp" {
  name = "${var.project_name}_db_subnt_grp"
  subnet_ids = aws_subnet.database[*].id
  tags = var.common_tags
  
}