variable "hcp_client_id" {}
variable "hcp_client_secret" {}
variable "hcp_project_id" {}
variable "hvn_id" {
  default = "vault-hvn"
}
variable "hvn_region" {
  default = "us-west-2"
}
variable "hvn_cidr" {
  default = "172.25.0.0/16"
}
variable "hvn_cloud_provider" {
  description = "Cloud provider for the HVN"
  type        = string
  default     = "aws"
}
variable "vault_cluster_id" {
  default = "vault-dedicated"
}
variable "vault_namespace" {
  default = "trusted-ai-secrets"
}

variable "gemini_api_key" {
    description = "LLM API Key"
    type = string
}
variable "prisma_airs_api_key" {
    description = "Prisma AIRS API key"
    type = string
}
variable "prisma_airs_profile" {
    description = "Prisma AIRS deployment profile"
    type = string
}

variable "app_image" {
  default = "gemini-chatbot"
}

variable "app_name" {
  default = "ai-chatbot"
}

variable "region" {
  description = "AWS region"
  type        = string
  default = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default = "ai-chatbot-cluster"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "db_name" {
  description = "Unique name to assign to RDS instance"
  default = "aiagentdb"
}

variable "db_username" {
  description = "RDS root username"
  default = "aiagent"
}

variable "db_password" {
  description = "RDS root user password (careful with special chars - not everything is accepted!)"
  sensitive   = true
}

variable "db_port" {
  default = 5432
}