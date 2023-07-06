## Environment NAME
variable "env" {
  description = " Deployment Environment"
  type        = string
  default     = "rosa"
}

## Creator Name
variable "created_by" {
  description = "Creator"
  type        = string
  default     = "myname"
}

## Key Files for connection to ec2 Instances
data "local_file" "ssh_key_pub" {
  filename = pathexpand("~/.ssh/id_rsa.pub")
}

data "local_file" "ssh_key_priv" {
  filename = pathexpand("~/.ssh/id_rsa")
}