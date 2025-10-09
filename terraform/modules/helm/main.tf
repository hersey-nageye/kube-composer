terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      # optional but good practice to pin:
      version = "2.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}





resource "helm_release" "this" {
  name             = var.name
  repository       = var.repo
  chart            = var.chart
  namespace        = var.namespace
  create_namespace = var.create_namespace
  reuse_values     = false
  reset_values     = true
  force_update     = true
  wait             = true
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 600


  version = var.chart_version == null ? null : var.chart_version

  values = var.values

  # only inject server.secretkey when the caller provided one
  dynamic "set_sensitive" {
    for_each = var.argocd_server_secretkey == null ? [] : [var.argocd_server_secretkey]
    content {
      name  = "configs.secret.extra.server\\.secretkey"
      value = set_sensitive.value
    }
  }
}
