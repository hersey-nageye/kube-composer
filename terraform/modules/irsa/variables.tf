########################################
# VARIABLES
########################################

variable "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the IAM OIDC provider for the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where the ServiceAccount exists"
  type        = string
}

variable "service_account" {
  description = "Name of the Kubernetes ServiceAccount"
  type        = string
}

variable "policy_json" {
  description = "IAM policy JSON granting permissions to this service account"
  type        = string
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
