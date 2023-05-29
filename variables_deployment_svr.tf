
variable "ec2_ami" {
  description = "AMI of EC2 Instance"
  type        = string
  default     = "ami-02396cdd13e9a1257"
}

variable "ec2_instance_type" {
  description = "Type of EC2 Instance"
  type        = string
  default     = "t2.micro"
}

variable "ec2_instance_name" {
  description = "Name of EC2 Instance"
  type        = string
  default     = "deployment_svr"
}

variable "ec2_inbound_network" {
  description = "Source network for connection to EC2 Instance"
  default = [
    "xx.xx.xx.xx/32" ## Replace with the IP address of your connection source
  ]
}
