
variable "windows_ami" {
  description = "AMI of Windows AD Instance"
  type        = string
  default     = "ami-06a1da2a231f90821"
}

variable "windows_instance_type" {
  description = "Type of EC2 Instance"
  type        = string
  default     = "t2.micro"
}

variable "windows_instance_name" {
  description = "Name of Windows Instance"
  type        = string
  default     = "ad_dns_svr"
}