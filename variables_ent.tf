
variable "ent_env" {
  description = " Deployment Environment - ENTERPRISE"
  type        = string
  default     = "enterprise-vpc"
}

locals {
  ent_vpc_cidr_block = "${var.ent_subnet_block_prefix}0/${var.ent_vpc_cidr_mask}"
  ent_vpc_name       = "${var.ent_env}-vpc"
  ent_subnet_count   = length(var.ent_priv_subnet_azs)
  ent_newbits        = format(var.ent_subnet_blocks - var.ent_vpc_cidr_mask)
}

variable "ent_aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ent_subnet_block_prefix" {
  description = "AWS VPC CIDR block Prefix"
  default     = "172.16.16."
}


variable "ent_vpc_cidr_mask" {
  description = "VPC CIDR block subnet mask"
  default     = "24"
}

variable "ent_subnet_blocks" {
  description = "Subnet mask for subnets created from VPC CIDR block"
  default     = "26"
}

variable "ent_priv_subnet_azs" {
  description = "Availability zones withing the region"
  type        = list(string)
  default = [
    "us-east-1a"
  ]
}