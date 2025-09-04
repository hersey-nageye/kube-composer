output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.control_plane.name

}

output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = aws_eks_cluster.control_plane.endpoint

}

output "nodes_sg_id" {
  description = "The security group ID for the worker nodes"
  value       = aws_security_group.nodes_sg.id

}

output "cluster_sg_id" {
  description = "The security group ID for the EKS cluster"
  value       = aws_security_group.control_plane_sg.id

}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the EKS cluster"
  value       = aws_iam_openid_connect_provider.this.arn

}

output "oidc_provider_url" {
  description = "The URL of the OIDC provider for the EKS cluster"
  value       = aws_iam_openid_connect_provider.this.url

}




