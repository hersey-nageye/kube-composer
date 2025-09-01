locals {
  region = "eu-west-2"
  # Common cluster-discovery tag key
  eks_cluster_tag_key = "kubernetes.io/cluster/${var.cluster_name}"

  # Tag sets
  subnet_tags_common = {
    (local.eks_cluster_tag_key) = "shared"
  }

  public_subnet_tags = merge(local.subnet_tags_common, {
    "kubernetes.io/role/elb" = "1"
  })

  private_subnet_tags = merge(local.subnet_tags_common, {
    "kubernetes.io/role/internal-elb" = "1"
  })
}
