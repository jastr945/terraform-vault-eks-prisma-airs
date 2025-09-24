provider "aws" {
  region = var.region
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_eks_cluster" "ai-chatbot-cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  version = var.kubernetes_version

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = var.tags
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.ai-chatbot-cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.node_instance_types

  tags = var.tags
}

# resource "helm_release" "vault_secrets_operator" {
#   name       = "vault-secrets-operator"
#   repository = "https://helm.releases.hashicorp.com"
#   chart      = "vault-secrets-operator"
#   version    = "0.10.0"
#   namespace  = "vault-secrets-operator"

#   create_namespace = true

#   values = [
#     <<EOF
# # Optional: customize VSO configuration
# replicaCount: 1
# vault:
#   address: "${var.vault_addr}"
#   auth:
#     method: "kubernetes"
# EOF
#   ]
# }

# resource "kubernetes_service_account_v1" "vault" {
#   metadata {
#     name      = "vault-auth"
#     namespace = "vault-secrets-operator"
#   }
#   automount_service_account_token = true
# }

# resource "kubernetes_secret_v1" "vault_token" {
#   metadata {
#     name      = kubernetes_service_account_v1.vault.metadata[0].name
#     namespace = "vault-secrets-operator"
#     annotations = {
#       "kubernetes.io/service-account.name" = "vault-auth"
#     }
#   }
#   type = "kubernetes.io/service-account-token"
#   wait_for_service_account_token = true
# }

# resource "kubernetes_cluster_role_binding_v1" "vault" {
#   metadata {
#     name = "role-tokenreview-binding"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "system:auth-delegator"
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account_v1.vault.metadata.0.name
#     namespace = "openshift-operators"
#   }
# }

resource "kubernetes_namespace_v1" "ai_chatbot_app" {
  metadata {
    name = "ai-chatbot"
  }
}
# #   lifecycle {
# #     ignore_changes = [
# #       metadata[0].annotations["openshift.io/sa.scc.mcs"],
# #       metadata[0].annotations["openshift.io/sa.scc.supplemental-groups"],
# #       metadata[0].annotations["openshift.io/sa.scc.uid-range"],
# #     ]
# #   }
# #   depends_on = [kubernetes_manifest.vault_secrets_operator_subscription]
# # }


# resource "kubernetes_service_account_v1" "ai_chatbot_app" {
#   metadata {
#     name      = "ai-chatbot-app"
#     namespace = var.openshift_namespace
#   }

#   lifecycle {
#     ignore_changes = [
#       image_pull_secret,
#       metadata[0].annotations["openshift.io/internal-registry-pull-secret-ref"],
#       secret,
#     ]
#   }
# }

# resource "kubernetes_service_account_v1" "ai_chatbot_app_vso_sa" {
#   metadata {
#     name      = "ai-chatbot-app-vso-sa"
#     namespace = var.openshift_namespace
#   }

#   lifecycle {
#     ignore_changes = [
#       image_pull_secret,
#       metadata[0].annotations["openshift.io/internal-registry-pull-secret-ref"],
#       secret,
#     ]
#   }
# }

# resource "kubernetes_cluster_role_binding" "ai_chatbot_app" {
#   metadata {
#     name = "ai-chatbot-app-binding"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "system:auth-delegator"
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account_v1.ai_chatbot_app.metadata[0].name
#     namespace = var.openshift_namespace
#   }
# }

# resource "kubernetes_manifest" "vault_connection" {
#   manifest = yamldecode(<<-EOF
#     kind: VaultConnection
#     apiVersion: secrets.hashicorp.com/v1beta1
#     metadata:
#       name: vault-connection
#       namespace: "${var.openshift_namespace}"
#     spec:
#       address: "${var.vault_addr}"
#     EOF
#   )

#   depends_on = [kubernetes_manifest.vault_secrets_operator_subscription]
# }

# resource "kubernetes_manifest" "vault_auth" {
  
#   manifest = yamldecode(<<-EOF
#     apiVersion: secrets.hashicorp.com/v1beta1
#     kind: VaultAuth
#     metadata:
#       name: chatbot-auth
#       namespace: "${var.openshift_namespace}"
#     spec:
#       vaultConnectionRef: "${kubernetes_manifest.vault_connection.object.metadata.name}"
#       method: jwt
#       mount: "${vault_jwt_auth_backend.jwt_auth.path}"
#       namespace: "${var.vault_namespace}"
#       allowedNamespaces: ["${var.openshift_namespace}"]
#       storageEncryption:
#         keyName: vso-cache-pw1
#         mount: transit-pw1
#       jwt:
#         audiences:
#           - "${var.openshift_namespace}"
#         role: "${vault_jwt_auth_backend_role.ai_chatbot_app_role.role_name}"
#         serviceAccount: chatbot-sa
#         tokenExpirationSeconds: 600
#     EOF
#   )

#   depends_on = [kubernetes_manifest.vault_secrets_operator_subscription]
# }

# resource "kubernetes_manifest" "vault_secret_gemini" {
  
#   manifest = yamldecode(<<-EOF
#     apiVersion: secrets.hashicorp.com/v1beta1
#     kind: VaultStaticSecret
#     metadata:
#       name: chatbot-secret-gemini
#       namespace: "${var.openshift_namespace}"
#     spec:
#       path: /v1/admin/kv/data/chatbot
#       mount: kv
#       type: kv-v2
#       destination:
#         name: GEMINI_API_KEY
#         create: false
#         overwrite: true
#       refreshAfter: 2s
#       syncConfig:
#         instantUpdates: true
#       vaultAuthRef: chatbot-auth
#   EOF
#   )

#   depends_on = [kubernetes_manifest.vault_auth]
# }

# resource "kubernetes_manifest" "vault_secret_airs_api_key" {
  
#   manifest = yamldecode(<<-EOF
#     apiVersion: secrets.hashicorp.com/v1beta1
#     kind: VaultStaticSecret
#     metadata:
#       name: chatbot-secret-airs-api-key
#       namespace: "${var.openshift_namespace}"
#     spec:
#       path: /v1/admin/kv/data/chatbot
#       mount: kv
#       type: kv-v2
#       destination:
#         name: PRISMA_AIRS_API_KEY
#         create: false
#         overwrite: true
#       refreshAfter: 2s
#       syncConfig:
#         instantUpdates: true
#       vaultAuthRef: chatbot-auth

#   EOF
#   )

#   depends_on = [kubernetes_manifest.vault_auth]
# }

# resource "kubernetes_manifest" "vault_secret_airs_profile" {
  
#   manifest = yamldecode(<<-EOF
#     apiVersion: secrets.hashicorp.com/v1beta1
#     kind: VaultStaticSecret
#     metadata:
#       name: chatbot-secret-airs-profile
#       namespace: "${var.openshift_namespace}"
#     spec:
#       path: /v1/admin/kv/data/chatbot
#       mount: kv
#       type: kv-v2
#       destination:
#         name: PRISMA_AIRS_PROFILE
#         create: false
#         overwrite: true
#       refreshAfter: 2s
#       syncConfig:
#         instantUpdates: true
#       vaultAuthRef: chatbot-auth
#   EOF
#   )

#   depends_on = [kubernetes_manifest.vault_auth]
# }

# data "vault_policy_document" "ai_chatbot_app_policy" {
#   rule {
#     path         = "/v1/admin/kv/data/chatbot"
#     capabilities = ["read", "list"]
#   }

#   rule {
#     path         = "${var.vault_transit_mount_path}/encrypt/${var.vault_transit_key_name}"
#     capabilities = ["create", "update"]
#   }

#   rule {
#     path         = "${var.vault_transit_mount_path}/decrypt/${var.vault_transit_key_name}"
#     capabilities = ["create", "update"]
#   }
# }

# resource "vault_policy" "ai_chatbot_app_policy" {
#   name      = "ai-chatbot-app-policy"
#   policy    = data.vault_policy_document.ai_chatbot_app_policy.hcl
# }

# # Enable JWT auth method
# resource "vault_jwt_auth_backend" "jwt_auth" {
#   path        = "vso"
#   type        = "jwt"
#   description = "JWT auth for OpenShift integration with VSO"

#   jwt_validation_pubkeys = var.openshift_jwt_keys
#   bound_issuer           = var.openshift_issuer
#   # Tune block for lease settings
#   tune {
#     default_lease_ttl = "1h"
#     max_lease_ttl     = "24h"
#   }
# }

# resource "vault_jwt_auth_backend_role" "ai_chatbot_app_role" {
#   backend   = vault_jwt_auth_backend.jwt_auth.path
#   role_name = var.openshift_namespace
#   role_type = "jwt"

#   bound_audiences = [
#     var.openshift_audience,
#     var.openshift_namespace
#   ]

#   bound_subject = "system:serviceaccount:${var.openshift_namespace}:${kubernetes_service_account_v1.ai_chatbot_app_vso_sa.metadata[0].name}"
#   user_claim    = "sub"

#   token_policies = [vault_policy.ai_chatbot_app_policy.name]
#   token_ttl      = 600  # 10 minutes
#   token_max_ttl  = 3600 # 1 hour
# }

# resource "kubernetes_deployment" "app" {
#   metadata {
#     name      = var.app_name
#     namespace = var.openshift_namespace
#     labels = {
#       app = var.app_name
#     }
#   }
#   spec {
#     replicas = var.replicas
#     selector {
#       match_labels = {
#         app = var.app_name
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app = var.app_name
#         }
#       }
#       spec {
#         container {
#           name  = var.app_name
#           image = var.image
#           port {
#             container_port = 5000
#           }
#           env {
#             # env vars come from the Kubernetes secret created by VSO
#             name = "GEMINI_API_KEY"
#             value_from {
#               secret_key_ref {
#                 name = "chatbot-secrets"
#                 key  = "GEMINI_API_KEY"
#               }
#             }
#           }
#           env {
#             name = "PRISMA_AIRS_API_KEY"
#             value_from {
#               secret_key_ref {
#                 name = "chatbot-secrets"
#                 key  = "PRISMA_AIRS_API_KEY"
#               }
#             }
#           }
#           env {
#             name = "PRISMA_AIRS_PROFILE"
#             value_from {
#               secret_key_ref {
#                 name = "chatbot-secrets"
#                 key  = "PRISMA_AIRS_PROFILE"
#               }
#             }
#           }
#           readiness_probe {
#             http_get {
#               path = "/token-suffix"
#               port = 5000
#             }
#             initial_delay_seconds = 5
#             period_seconds        = 10
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "app_svc" {
#   metadata {
#     name      = "${var.app_name}-svc"
#     namespace = var.openshift_namespace
#     labels = {
#       app = var.app_name
#     }
#   }
#   spec {
#     selector = {
#       app = var.app_name
#     }
#     port {
#       port        = 80
#       target_port = 5000
#       protocol    = "TCP"
#     }
#   }
#   depends_on = [kubernetes_deployment.app, kubernetes_manifest.vault_secret_gemini, kubernetes_manifest.vault_secret_airs_api_key, kubernetes_manifest.vault_secret_airs_profile]
# }

# resource "kubernetes_manifest" "route" {
#   manifest = {
#     apiVersion = "route.openshift.io/v1"
#     kind       = "Route"
#     metadata = {
#       name      = "${var.app_name}-route"
#       namespace = "${var.openshift_namespace}"
#     }
#     spec = {
#       to = {
#         kind = "Service"
#         name = "${kubernetes_service.app_svc.metadata[0].name}"
#       }
#       port = {
#         targetPort = 80
#       }
#       tls = {
#         termination                   = "edge"
#         insecureEdgeTerminationPolicy = "Allow"
#       }
#     }
#   }
#   depends_on = [kubernetes_service.app_svc]
# }