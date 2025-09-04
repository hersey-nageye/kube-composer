########################################
# LOCALS
# - Build trust policy conditions
########################################

locals {
  # Strip https:// from OIDC URL for use in IAM condition keys
  oidc_url_no_scheme = replace(var.oidc_provider_url, "https://", "")

  # Build condition keys for aud and sub
  oidc_sub_key = "${local.oidc_url_no_scheme}:sub"
  oidc_aud_key = "${local.oidc_url_no_scheme}:aud"

  # Full subject for the ServiceAccount
  service_account_subject = "system:serviceaccount:${var.namespace}:${var.service_account}"
}
