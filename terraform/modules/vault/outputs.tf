output "vault_public_url" {
  value = hcp_vault_cluster.vault.vault_public_endpoint_url
}

output "vault_kubernetes_auth_backend_path" {
  value = vault_auth_backend.kubernetes.path
}