variable "name" {
  description = "name of the Helm release"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy the Helm chart into"
  type        = string

}

variable "chart" {
  description = "The name of the Helm chart to deploy"
  type        = string
}

variable "repo" {
  description = "The Helm chart repository URL"
  type        = string
}

variable "chart_version" {
  description = "The version of the Helm chart to deploy"
  type        = string
  default     = null
}

variable "values" {
  description = "A list of YAML values files to pass to the Helm chart"
  type        = list(string)
  default     = []

}

variable "create_namespace" {
  description = "Whether to create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "set_values" {
  description = "Plain helm set values (name => value)."
  type        = map(string)
  default     = {}
}

variable "set_sensitive_values" {
  description = "Sensitive helm set values (name => value)."
  type        = map(string)
  default     = {}
}

variable "argocd_server_secretkey" {
  type      = string
  sensitive = true
  default   = null
}

