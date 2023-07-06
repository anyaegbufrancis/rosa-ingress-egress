## Environment name for each ENV
variable "rosa_env" {
  description = " Deployment Environment - ROSA"
  type        = string
  default     = "rosa-vpc"
}

## Locals for Each Environment
locals {
  rosa_vpc_cidr_block = "${var.rosa_subnet_block_prefix}0/${var.rosa_vpc_cidr_mask}"
  rosa_vpc_name       = "${var.rosa_env}-vpc"
  rosa_subnet_count   = length(var.rosa_priv_subnet_azs)
  rosa_newbits        = format(var.rosa_subnet_blocks - var.rosa_vpc_cidr_mask)
}

## Region Name for each Environments
variable "rosa_aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

## VPC CIDR For Each Environment
variable "rosa_subnet_block_prefix" {
  description = "AWS VPC CIDR block Prefix"
  default     = "192.168.0."
}

## VPC Prefix Lenght for each environment
variable "rosa_vpc_cidr_mask" {
  description = "VPC CIDR block subnet mask"
  default     = "24"
}

## Subnet Prefix lenght for each VPC
variable "rosa_subnet_blocks" {
  description = "Subnet mask for subnets created from VPC CIDR block"
  default     = "26"
}

## AZs within the VPCs
variable "rosa_priv_subnet_azs" {
  description = "Availability zones withing the region"
  type        = list(string)
  default = [
    "us-east-1a"
    , "us-east-1b"
    , "us-east-1c"
  ]
}