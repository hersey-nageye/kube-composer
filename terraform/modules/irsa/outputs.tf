output "role_arn" {
  description = "IAM Role ARN for the Kubernetes ServiceAccount"
  value       = aws_iam_role.this.arn
}

