
################################################################################
# vpc
################################################################################

variable "region" {
  default = "us-east-2"
}

variable "name" {
  type    = string
  default = "onyi"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_tags" {}

variable "public_subnet_names" {
  type = list(any)
}

variable "private_subnet_names" {
  type = list(any)
}

variable "public_route_table_tags" {}

variable "private_route_table_tags" {}

variable "nat_gateway_tags" {}

variable "nat_eip_tags" {}

variable "tags" {
  description = "A mapping of tags to assign to all resources."
  type        = map(string)
  default     = {}
}


variable "cluster_name" {
  default = "onyeka-eks-19-8-0"
  type    = string
}

