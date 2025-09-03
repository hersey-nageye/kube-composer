variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"

}

variable "vpc_id" {
  description = "The VPC ID where the EKS cluster and nodes will be deployed"
  type        = string

}

variable "public_subnet_ids" {
  description = "List of subnet IDs for the public subnets"
  type        = list(string)

}

variable "private_subnet_ids" {
  description = "List of subnet IDs for the EKS worker nodes (should be private subnets)"
  type        = list(string)

}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS cluster API endpoint is publicly accessible"
  type        = bool

}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public API endpoint"
  type        = list(string)

}

variable "endpoint_private_access" {
  description = "Whether the EKS cluster API endpoint is privately accessible"
  type        = bool

}

variable "node_disk_size" {
  description = "Disk size (in GB) for each worker node"
  type        = number
  default     = 50

}

variable "instance_types" {
  description = "List of instance types for the worker nodes"
  type        = list(string)
  default     = ["t3a.large", "t3.large"]

}

variable "node_min_size" {
  description = "Minimum number of worker nodes in the node group"
  type        = number

}

variable "node_desired_size" {
  description = "Desired number of worker nodes in the node group"
  type        = number

}

variable "node_max_size" {
  description = "Maximum number of worker nodes in the node group"
  type        = number

}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "project_name" {
  description = "Name of the project, used for tagging resources"
  type        = string

}

variable "capacity_type" {
  description = "Capacity type for the node group (e.g., ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}
