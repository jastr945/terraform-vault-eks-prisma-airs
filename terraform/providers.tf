terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.109.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "5.2.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.26.0"
    }
  }
}
