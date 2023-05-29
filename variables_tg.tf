variable "tg_name" {
  description = "Deployment Environment"
  type        = string
  default     = "rosa"
}

variable "rosa_attach" {
  description = "Deployment Environment"
  type        = string
  default     = "rosa_vpc"
}

variable "ent_attach" {
  description = "Deployment Environment"
  type        = string
  default     = "ent_vpc"
}

variable "net_attach" {
  description = "Deployment Environment"
  type        = string
  default     = "net_vpc"
}