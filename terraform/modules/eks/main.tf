data "aws_partition" "current" {}


########################################
# IAM ROLES AND ATTACHMENTS
# - EKS control-plane role
# - EKS node-group role
# - Required AWS-managed policy attachments
########################################

# Control-plane IAM role
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

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

# resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
#   role       = aws_iam_role.eks_cluster.name
#   policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
# }

# Node-group IAM role
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

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

########################################
# SECURITY GROUPS
# - Cluster SG (attached to control-plane ENIs)
# - Nodes SG (attached to worker EC2 instances)
# - Rules allow cluster <-> nodes comms and egress
########################################

resource "aws_security_group" "control_plane_sg" {
  name        = "${var.cluster_name}-control-plane-sg"
  description = "EKS control-plane SG"
  vpc_id      = var.vpc_id
  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-control-plane-sg"
  })
}

resource "aws_security_group" "nodes_sg" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "EKS worker nodes SG"
  vpc_id      = var.vpc_id
  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-nodes-sg"
  })
}

# Allow nodes -> cluster and cluster -> nodes (all node/control-plane ports managed by EKS)
resource "aws_vpc_security_group_ingress_rule" "control_plane_ingress_from_nodes" {
  security_group_id            = aws_security_group.control_plane_sg.id
  referenced_security_group_id = aws_security_group.nodes_sg.id
  description                  = "Allow worker nodes to communicate with control plane"
  from_port                    = 0
  to_port                      = 0
  ip_protocol                  = "tcp"
}


resource "aws_vpc_security_group_egress_rule" "control_plane_egress_all" {
  security_group_id = aws_security_group.control_plane_sg.id
  description       = "Allow all outbound traffic from control plane"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}

resource "aws_vpc_security_group_ingress_rule" "nodes_ingress_from_control_plane" {
  security_group_id            = aws_security_group.nodes_sg.id
  referenced_security_group_id = aws_security_group.control_plane_sg.id
  description                  = "Allow worker nodes to receive communication from control plane"
  from_port                    = 0
  to_port                      = 0
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "nodes_egress_all" {
  security_group_id = aws_security_group.nodes_sg.id
  description       = "Allow all outbound traffic from worker nodes"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}

########################################
# EKS CLUSTER (CONTROL PLANE)
# - Places control-plane ENIs in PUBLIC subnets (like your tutor)
# - Public endpoint enabled with CIDR allow-list
########################################

resource "aws_eks_cluster" "control_plane" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.public_subnet_ids # public subnets
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

data "aws_eks_cluster" "cluster_info" {
  name = aws_eks_cluster.control_plane.name
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = data.aws_eks_cluster.cluster_info.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10df6"] # EKS OIDC thumbprint (always this value) - Can make dynamic after MVP using tls_certificate data source
  tags            = merge(var.common_tags, { Name = "${var.project_name}-eks-oidc-provider" })
}

########################################
# MANAGED NODE GROUP
# - Runs EC2 worker nodes in PRIVATE subnets
# - Autoscaling min/desired/max
########################################

resource "aws_eks_node_group" "worker_nodes" {
  cluster_name    = aws_eks_cluster.control_plane.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids # private subnets
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

########################################
# (RECOMMENDED) CORE ADDONS
# - VPC CNI, CoreDNS, kube-proxy
# - You can pin addon_version if you want determinism
########################################

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.control_plane.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.worker_nodes]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.control_plane.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.worker_nodes]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.control_plane.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.worker_nodes]
}
