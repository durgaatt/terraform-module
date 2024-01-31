variable "cidr_block" {
  
}
variable "project_name" {
  type = string
  
}
variable "enable_dns_hostnames" {
  default = true
}
variable "enable_dns_support" {
  default = true
}
variable "common_tags" {
  default = {}
}
variable "public_subnet_cidr" {
  type        = list

  validation {
    condition     = length(var.public_subnet_cidr) == 2
    error_message = "Please enter only 2 CIDR public subnets:"
  }
}

variable "private_subnet_cidr" {
  type        = list
  validation {
  condition     = length(var.private_subnet_cidr) == 2
  error_message = "Please enter only 2 CIDR private subnets:"
  }
}
variable "database_subnet_cidr" {
  type        = list
  validation {
  condition     = length(var.database_subnet_cidr) == 2
  error_message = "Please enter only 2 CIDR database subnets:"
  }
}