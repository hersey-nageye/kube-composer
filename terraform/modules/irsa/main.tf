########################################
# IAM ROLE (TRUST POLICY)
# - Trusts the cluster's OIDC provider
# - Restricted to the given ServiceAccount
########################################

resource "aws_iam_role" "this" {
  name = "irsa-${var.namespace}-${var.service_account}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            (local.oidc_aud_key) = "sts.amazonaws.com",
            (local.oidc_sub_key) = local.service_account_subject
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    ServiceAccount = "${var.namespace}/${var.service_account}"
  })
}

########################################
# IAM POLICY (INLINE)
# - Define the permissions this SA should get
# - Example: Route53 change records for cert-manager
########################################

resource "aws_iam_policy" "this" {
  name   = "irsa-${var.namespace}-${var.service_account}"
  policy = var.policy_json
  tags   = var.tags
}

########################################
# ATTACH POLICY TO ROLE
########################################

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
