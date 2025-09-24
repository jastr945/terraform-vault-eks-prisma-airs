output "k8s_cluster_name" {
    description = "The name of the Kubernetes cluster"
    value       = aws_eks_cluster.ai-chatbot-cluster.name
}

output "k8s_cluster_endpoint" {
    description = "The URL (endpoint) of the Kubernetes cluster"
    value       = aws_eks_cluster.ai-chatbot-cluster.endpoint
}