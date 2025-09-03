module "vpc" {
  source                    = "./modules/vpc"
  vpc_cidr                  = var.vpc_cidr
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_subnet_cidrs      = var.private_subnet_cidrs
  subnet_availability_zones = var.subnet_availability_zones
  common_tags               = var.common_tags
  project_name              = var.project_name
  cluster_name              = var.cluster_name
}

module "eks" {
  source                               = "./modules/eks"
  cluster_name                         = var.cluster_name
  vpc_id                               = module.vpc.vpc_id
  public_subnet_ids                    = module.vpc.public_subnet_ids
  private_subnet_ids                   = module.vpc.private_subnet_ids
  common_tags                          = var.common_tags
  project_name                         = var.project_name
  instance_types                       = var.instance_types
  node_min_size                        = var.node_min_size
  node_desired_size                    = var.node_desired_size
  node_max_size                        = var.node_max_size
  node_disk_size                       = var.node_disk_size
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  endpoint_private_access              = var.endpoint_private_access
  capacity_type                        = var.capacity_type

}
