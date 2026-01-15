# Data source to get current AWS partition (for constructing ARNs)
# Purpose: To avoid hardcoding "aws" in ARNs as well as making the module
# more reusable across different partitions (e.g., aws, aws-cn, aws-us-gov)
data "aws_partition" "current" {}


# Control-plane IAM role
# Purpose: Role assumed by EKS to manage the control-plane. Role gives EKS permissions
# to manage AWS resources without needing your AWS account credentials.
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-eks-cluster-role"
    }
  )
}

# Attach required policies to the EKS control-plane role
# Purpose: Grants the EKS control-plane role the necessary permissions to manage AWS resources.
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Node-group IAM role
# Purpose: Role assumed by EKS worker nodes to interact with AWS resources.
resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-eks-nodes-role"
    }
  )
}

# Attach AmazonEKSWorkerNodePolicy to the eks_nodes IAM role
# Purpose: Grants EC2 instances (worker nodes) the necessary permissions to authenticate
# to the EKS control-plane and perform AWS API calls.
resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach AmazonEKS_CNI_Policy to the eks_nodes IAM role
# Purpose: Grants worker nodes permissions to manage networking resources
resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attach AmazonEC2ContainerRegistryReadOnly to the eks_nodes IAM role
# Purpose: Grants worker nodes read-only access to Amazon ECR repositories
resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Control Plane Security Group
# Purpose: To manage inbound and outbound traffic to/from the EKS control-plane
resource "aws_security_group" "control_plane_sg" {
  name        = "${var.cluster_name}-control-plane-sg"
  description = "EKS control-plane SG"
  vpc_id      = var.vpc_id
  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-control-plane-sg"
  })
}

# Worker Nodes Security Group
# Purpose: To manage inbound and outbound traffic to/from the EKS worker nodes
resource "aws_security_group" "nodes_sg" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "EKS worker nodes SG"
  vpc_id      = var.vpc_id
  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-nodes-sg"
  })
}

# Inbound rule for control plane SG to allow inbound traffic from worker nodes SG
resource "aws_vpc_security_group_ingress_rule" "control_plane_ingress_from_nodes" {
  security_group_id            = aws_security_group.control_plane_sg.id
  referenced_security_group_id = aws_security_group.nodes_sg.id
  description                  = "Allow worker nodes to communicate with control plane"
  from_port                    = 0
  to_port                      = 0
  ip_protocol                  = "tcp"
}

# Outbound rule for control plane SG to allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "control_plane_egress_all" {
  security_group_id = aws_security_group.control_plane_sg.id
  description       = "Allow all outbound traffic from control plane"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}

# Inbound rule for worker nodes SG to allow inbound traffic from control plane SG
resource "aws_vpc_security_group_ingress_rule" "nodes_ingress_from_control_plane" {
  security_group_id            = aws_security_group.nodes_sg.id
  referenced_security_group_id = aws_security_group.control_plane_sg.id
  description                  = "Allow worker nodes to receive communication from control plane"
  from_port                    = 0
  to_port                      = 0
  ip_protocol                  = "tcp"
}

# Outbound rule for worker nodes SG to allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "nodes_egress_all" {
  security_group_id = aws_security_group.nodes_sg.id
  description       = "Allow all outbound traffic from worker nodes"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}

# EKS Cluster (Control Plane)
# Purpose: Creates the EKS cluster. The VPC config block manages
# communication with the custom VPC.
resource "aws_eks_cluster" "control_plane" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.public_subnet_ids
    endpoint_public_access  = var.cluster_endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.control_plane_sg.id]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-control_plane"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

# OIDC provider for EKS cluster
# Purpose: Read the OIDC issuer URL from the EKS cluster to create the IAM OIDC provider
data "aws_eks_cluster" "cluster_info" {
  name = aws_eks_cluster.control_plane.name
}

# Create the OIDC provider
# Purpose: Makes IRSA possible by registering OIDC provider with IAM
resource "aws_iam_openid_connect_provider" "this" {
  url             = data.aws_eks_cluster.cluster_info.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10df6"] # EKS OIDC thumbprint (always this value) - Can make dynamic after MVP using tls_certificate data source
  tags            = merge(var.common_tags, { Name = "${var.project_name}-eks-oidc-provider" })
}

# EKS Node Group (Worker Nodes)
# Purpose: Creates a managed node group for the EKS cluster. The node group
# provisions EC2 instances in private subnets to run workloads.
resource "aws_eks_node_group" "worker_nodes" {
  cluster_name    = aws_eks_cluster.control_plane.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = var.capacity_type

  scaling_config {
    min_size     = var.node_min_size
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
  }

  disk_size      = var.node_disk_size
  instance_types = var.instance_types

  update_config { max_unavailable = 1 }
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-worker-nodes"
  })

  depends_on = [
    aws_iam_role_policy_attachment.nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes_AmazonEC2ContainerRegistryReadOnly
  ]
}

# Core EKS Add-ons
# Purpose: Deploys essential EKS add-ons explicitly to ensure they are present and configured correctly.

# VPC-CNI (Pod Networking)
# Purpose: Assigns VPC IP addresses to pods for network connectivity
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.control_plane.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.worker_nodes]
}

# CoreDNS (Cluster DNS)
# Purpose: Provides DNS resolution for services within the cluster
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.control_plane.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.worker_nodes]
}

# Kube-Proxy (Network Proxy)
# Purpose: Manages network rules on nodes to allow communication to pods
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.control_plane.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.worker_nodes]
}
