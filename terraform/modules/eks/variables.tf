variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)

} 

variable "vault_addr" {
  description = "Address/URL of Vault (e.g. https://<vault-host>:8200)"
  type        = string
}

variable "vault_kubernetes_auth_backend_path" {
  description = "Path where the Kubernetes auth method is enabled in Vault"
  type        = string
}