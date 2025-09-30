# terraform-vault-eks-prisma-airs
Secure, Terraform-deployed AI workloads on AWS EKS, with secrets managed via HCP Vault Dedicated and delivered using Vault Secrets Operator. Security guardrails provided by Prisma AIRS.

## Why This Matters

In today’s fast-paced AI landscape, securely deploying and managing AI workloads is a critical challenge. Organizations need a solution that not only scales effortlessly but also ensures that sensitive data—like API keys and model secrets—is protected at every layer. This repository addresses that challenge by combining best-in-class tools for infrastructure automation, secrets management, and runtime security.

By leveraging Terraform, this solution automates the provisioning of both the AWS EKS cluster and the  HashiCorp Vault Dedicated cluster, drastically reducing the time and complexity of setup. The Vault Secrets Operator (VSO) ensures that secrets are dynamically injected into the AI workload, eliminating manual handling of sensitive information and reducing operational risk.

Prisma AIRS AI Runtime Security - API Intercept by Palo Alto Networks provides proactive AI guardrails, monitoring the behavior of the FastAPI chatbot in real-time. This means your AI workloads are not only secure from a secrets perspective but also protected from unintended or unsafe outputs, helping organizations meet compliance requirements and maintain trust with end users.

With this deployment pattern, teams gain a fully automated, secure, and scalable AI environment that can be easily replicated across projects or accounts, allowing developers to focus on building intelligence rather than managing infrastructure or worrying about security gaps. It’s the intersection of speed, safety, and operational efficiency—exactly what modern AI teams need to accelerate innovation responsibly.

## What is deployed in this repo

| Component                        | Purpose                            |
| -------------------------------- | ---------------------------------- |
| **Python app (FastAPI)**           | Gemini-based chatbot with built-in guardrails by Palo Alto Networks Prisma AIRS            |
| **AWS EKS**         | Runs your app as a pod             |
| **HCP Vault Dedicated**          | Stores secrets in `kv-v2`          |
| **Vault Secrets Operator (VSO)** | Pulls secrets into EKS      |
| **Terraform**                    | Automates HCP Vault + Kubernetes setup |

## Prerequisites

- HCP account and Vault CLI access
- AWS account and CLI access
- Docker
- Terraform v1.13.3 or later
- Helm
- Kubectl
- Prisma AIRS API access + key (from Palo Alto Networks)
- Gemini API key

## Local Setup

## Provision basic infrastructure

To stand up the basic infrastructure, a few credentials must be configured:  

1. Copy `secrets.auto.tfvars.sample` and rename it to `secrets.auto.tfvars`.
 ```bash
    cd terraform
    cp secrets.auto.tfvars.sample secrets.auto.tfvars
   ```

1. Create an HCP account and follow the [authentication guide](https://registry.terraform.io/providers/hashicorp/hcp/latest/docs/guides/auth) to set up and retrieve your project ID and client secret.  

13. Fill in all required credentials.vPrisma AIRS requires API access; make sure you have a valid key. Refer to the [official Prisma AIRS documentation](https://docs.paloaltonetworks.com/ai-runtime-security/activation-and-onboarding/activate-your-ai-runtime-security-license/create-an-ai-instance-deployment-profile-in-csp) for setup details.  

1. Export your AWS access key and secret key in the console.  
1. Deploy with Terraform:  
   ```bash
   terraform init
   terraform plan
   ```
1. Review the plan, then apply:
    ```bash
   terraform apply --auto-approve
   ```
At the end of this setup, Terraform provisions the core infrastructure:
- HCP Vault Dedicated cluster
- AWS EKS cluster

## Dockerize the app

Build a Docker image and push it to Amazon ECR:

```sh
# Exit the Terraform repo and navigate to the app directory
cd ../app

# Build the Docker image for amd64 architecture
docker buildx build --platform linux/amd64 -t ai-chatbot-eks:latest .

# Authenticate Docker to your ECR registry
aws ecr get-login-password --region us-west-2 \
  | docker login --username AWS \
  --password-stdin <aws_account_number>.dkr.ecr.us-west-2.amazonaws.com

# Create the ECR repository (if it doesn't exist)
aws ecr create-repository --repository-name ai-chatbot-eks --region us-west-2

# Tag your image for ECR
docker tag ai-chatbot-eks:latest <aws_account_number>.dkr.ecr.us-west-2.amazonaws.com/ai-chatbot-eks:latest

# Push the image to ECR
docker push <aws_account_number>.dkr.ecr.us-west-2.amazonaws.com/ai-chatbot-eks:latest
```

Replace `<aws_account_number>` with your actual AWS account number.

## EKS and VSO Setup

### 1. Connect to Your EKS Cluster

```sh
aws eks update-kubeconfig --name ai-chatbot-cluster --region us-west-2
```

---

### 2. Install Vault Secrets Operator (VSO) with Helm

Follow the [HashiCorp Validated Pattern](https://developer.hashicorp.com/validated-patterns/vault/vault-kubernetes-auth#install-vault-secrets-operator-vso).  
**Note:** When prompted for your Vault address, provide only the domain (remove `https://`).

---

### 3. Apply Kubernetes Manifests

Navigate to the manifests directory:

```sh
cd modules/k8s-vso/k8s-manifests
```

Create the namespace:

```sh
kubectl apply -f namespace.yaml
```

Create the service account and Vault auth secret:

```sh
kubectl apply -f vault_auth.yaml
```

---

### 4. Configure Vault Kubernetes Auth

Export required values as environment variables:

```sh
export SA_TOKEN=$(kubectl get secret vault-auth-secret -n ai-chatbot \
  -o jsonpath="{.data.token}" | base64 --decode)

export KUBERNETES_CA=$(kubectl get secret vault-auth-secret -n ai-chatbot \
  -o jsonpath="{.data['ca\.crt']}" | base64 --decode)

export KUBERNETES_URL=$(kubectl config view --minify \
  -o jsonpath='{.clusters[0].cluster.server}')
```

---

### 5. Authenticate with Vault

- Go to the [HCP Console](https://portal.cloud.hashicorp.com).
- Navigate to **Vault Dedicated** > your cluster.
- Click **Generate Token** and copy it.

```sh
export VAULT_ADDR="<vault cluster url>"
vault login
```
Paste your token when prompted.

---

### 6. Configure Vault Kubernetes Auth Method

```sh
vault write -namespace="admin" auth/kubernetes/config \
  use_annotations_as_alias_metadata=true \
  token_reviewer_jwt="${SA_TOKEN}" \
  kubernetes_host="${KUBERNETES_URL}" \
  kubernetes_ca_cert="${KUBERNETES_CA}"
```

---

### 7. Create Required Role Bindings

```sh
kubectl apply -f k8s_config.yaml
```

---

### 8. Test Vault Access

```sh
export APP_TOKEN=$(vault write -namespace="admin" -field="token" \
  auth/kubernetes/login \
  role=ai-chatbot-role \
  jwt=$(kubectl create token -n ai-chatbot chatbot))

VAULT_TOKEN=$APP_TOKEN vault kv get \
  -namespace="admin" \
  -mount=kv chatbot
```

You should see the secrets stored in Vault for the chatbot app.

---

### 9. Deploy the App

Edit the AWS account in the image name if needed, then deploy:

```sh
kubectl apply -f deployment.yaml
```

---

### 10. Access the App

Check the load balancer service:

```sh
kubectl -n ai-chatbot get svc ai-chatbot-svc
```

Open the `EXTERNAL-IP` in your browser.

## Cleanup

Destroy all infra by running:

```sh
terraform destroy
```