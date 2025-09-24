output "vault_url" {
  value = module.vault.vault_public_url
}
output "eks_cluster_endpoint" {
  value = module.k8s-vso.k8s_cluster_endpoint
}
output "eks_cluster_name" {
  value = module.k8s-vso.k8s_cluster_name
}