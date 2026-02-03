# Creating IAM role to allow Kubernetes service account to assume this specific role
# this is achieved by connecting the IAM role with the OIDC provider of the EKS cluster
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

# Creating a trust policy to regulate which service account can assume this IAM role
resource "aws_iam_policy" "this" {
  name   = "irsa-${var.namespace}-${var.service_account}"
  policy = var.policy_json
  tags   = var.tags
}

# Attaching the created trust policy to the IAM role
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
