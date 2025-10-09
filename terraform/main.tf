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

module "irsa_cert_manager" {
  source            = "./modules/irsa"
  namespace         = var.cert_manager_namespace
  service_account   = var.cert_manager_service_account
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  policy_json       = file("${path.root}/modules/irsa/policies/cert-manager-route53.json")
  tags              = var.common_tags
  depends_on        = [module.eks]

}

module "irsa_external_dns" {
  source            = "./modules/irsa"
  namespace         = var.dns_namespace
  service_account   = var.dns_service_account
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  policy_json       = file("${path.root}/modules/irsa/policies/external-dns-route53.json")
  tags              = var.common_tags
  depends_on        = [module.eks]

}

module "helm_cert_manager" {
  source           = "./modules/helm"
  name             = "cert-manager"
  chart            = "cert-manager"
  repo             = "https://charts.jetstack.io"
  namespace        = "cert-manager"
  create_namespace = true
  chart_version    = "v1.14.4"
  values           = [file("${path.root}/modules/helm/values/cert-manager-values.yaml")]

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.irsa_cert_manager]

}

module "helm_external_dns" {
  source           = "./modules/helm"
  name             = "external-dns"
  chart            = "external-dns"
  repo             = "https://kubernetes-sigs.github.io/external-dns/"
  namespace        = "kube-system"
  create_namespace = true
  chart_version    = "1.17.0"
  values           = [file("${path.root}/modules/helm/values/external-dns-values.yaml")]

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.irsa_external_dns]

}

module "helm_ingress_nginx" {
  source           = "./modules/helm"
  name             = "ingress-nginx"
  chart            = "ingress-nginx"
  repo             = "https://kubernetes.github.io/ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]

}

module "helm_argo_cd" {
  source           = "./modules/helm"
  name             = "argocd"
  chart            = "argo-cd"
  repo             = "https://argoproj.github.io/argo-helm"
  chart_version    = "8.4.0"
  namespace        = "argo-cd"
  create_namespace = true
  values           = [file("${path.root}/modules/helm/values/argocd.yaml")]

  argocd_server_secretkey = var.argocd_server_secretkey

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.helm.ingress_nginx]

}


