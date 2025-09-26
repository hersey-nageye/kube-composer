variable "vpc_cidr" {
  description = "CIDR block for the VPC"
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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)

}

variable "project_name" {
  description = "Name of the project, used for tagging resources"
  type        = string

}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string

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

}

variable "instance_types" {
  description = "List of instance types for the worker nodes"
  type        = list(string)

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

variable "capacity_type" {
  description = "Capacity type for the EKS node group (e.g., ON_DEMAND or SPOT)"
  type        = string

}

variable "cert_manager_namespace" {
  description = "Kubernetes namespace for the cert-manager ServiceAccount"
  type        = string

}

variable "cert_manager_service_account" {
  description = "Name of the cert-manager Kubernetes ServiceAccount"
  type        = string

}

# variable "cert_manager_policy_json" {
#   description = "IAM policy JSON granting permissions to the cert-manager service account"
#   type        = string

# }

variable "dns_namespace" {
  description = "Kubernetes namespace for the external-dns ServiceAccount"
  type        = string

}

variable "dns_service_account" {
  description = "Name of the external-dns Kubernetes ServiceAccount"
  type        = string

}

variable "argocd_server_secretkey" {
  type      = string
  sensitive = true
}


# variable "dns_policy_json" {
#   description = "IAM policy JSON granting permissions to the external-dns service account"
#   type        = string

# }

# variable "cert_manager_name" {
#   description = "Name of the Helm release for cert-manager"
#   type        = string

# }
