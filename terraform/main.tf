module "vault" {
  source              = "./modules/vault"
  hcp_client_id       = var.hcp_client_id
  hcp_client_secret   = var.hcp_client_secret
  hcp_project_id      = var.hcp_project_id
  hvn_id              = var.hvn_id
  hvn_region          = var.hvn_region
  hvn_cidr            = var.hvn_cidr
  hvn_cloud_provider  = var.hvn_cloud_provider
  vault_cluster_id    = var.vault_cluster_id
  vault_namespace     = var.vault_namespace
  gemini_api_key      = var.gemini_api_key
  prisma_airs_api_key = var.prisma_airs_api_key
  prisma_airs_profile = var.prisma_airs_profile
}

module "k8s-vso" {
  source                             = "./modules/k8s-vso"
  region                             = var.region
  cluster_name                       = var.cluster_name
  subnet_ids                         = var.subnet_ids
  kubernetes_version                 = var.kubernetes_version
  tags                               = var.tags
  node_desired_size                  = var.node_desired_size
  node_max_size                      = var.node_max_size
  node_min_size                      = var.node_min_size
  node_instance_types                = var.node_instance_types
  vault_addr                         = module.vault.vault_public_url
  vault_kubernetes_auth_backend_path = module.vault.vault_kubernetes_auth_backend_path
}
