variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string

}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)

}

variable "project_name" {
  description = "Name of the project, used for tagging resources"
  type        = string

}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)

}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)

}

variable "subnet_availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)

}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string

}
