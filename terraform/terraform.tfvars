# Tags

common_tags = {
  Project = "kube-composer"
  Owner   = "hersey-nageye"
}

project_name = "eks-project"

# VPC

vpc_cidr                  = "10.0.0.0/16"
subnet_availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs      = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

# EKS Cluster
cluster_name                         = "kube-composer-cluster"
node_min_size                        = 1
node_desired_size                    = 1
node_max_size                        = 1
node_disk_size                       = 20
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
endpoint_private_access              = false
instance_types                       = ["t3.small"]
capacity_type                        = "SPOT"

