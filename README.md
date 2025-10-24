# terraform-vault-eks-prisma-airs
Secure, Terraform-deployed AI workloads on AWS EKS, with secrets managed via HCP Vault Dedicated and delivered using Vault Secrets Operator. Security guardrails provided by Prisma AIRS.

This repo includes two example AI applications (a chatbot and an agent) deployed on Kubernetes with secrets injected from Vault. It integrates the Prisma AIRS API to scan prompts and model outputs for malicious behavior.

> **Note:**  The steps in this README are intentionally detailed and verbose to serve as a tutorial and enhance the learning experience.

## Why This Matters

In today’s fast-paced AI landscape, securely deploying and managing AI workloads is a critical challenge. Organizations need a solution that not only scales effortlessly but also ensures that sensitive data - like API keys and model secrets - is protected at every layer. This repository addresses that challenge by combining best-in-class tools for infrastructure automation, secrets management, and runtime security.

By leveraging **Terraform**, this solution automates the provisioning of both the **AWS EKS** cluster and the **HashiCorp Vault Dedicated** cluster, drastically reducing the time and complexity of setup. The **Vault Secrets Operator (VSO)** ensures that secrets are dynamically injected into the AI workload, eliminating manual handling of sensitive information and reducing operational risk.

**Prisma AIRS AI Runtime Security** - API Intercept by **Palo Alto Networks** provides proactive AI guardrails, monitoring the behavior of the FastAPI chatbot in real-time. This means your AI workloads are not only secure from a secrets perspective but also protected from unintended or unsafe outputs, helping organizations meet compliance requirements and maintain trust with end users.

With this deployment pattern, teams gain a fully automated, secure, and scalable AI environment that can be easily replicated across projects or accounts, allowing developers to focus on building the internal logic of AI applications rather than managing infrastructure or worrying about security gaps. It’s the intersection of speed, safety, and operational efficiency - exactly what modern AI teams need to accelerate innovation responsibly.

## What is deployed in this repo

| Component                        | Purpose                            |
| -------------------------------- | ---------------------------------- |
| **Use case #1: AI Chatbot (FastAPI)**         | Gemini-based chatbot with built-in guardrails by Palo Alto Networks Prisma AIRS|
| **Use case #2: AI Agent (FastAPI) on LangGraph, LangChain** | Gemini-based agent (helpful infrastructure assistant) leveraging Terraform MCP with built-in guardrails Prisma AIRS|
| **AWS EKS**         | Runs your apps as a pods             |
| **HCP Vault Dedicated**          | Stores secrets in `kv-v2`, generates **dynamic** database credentials          |
| **Vault Secrets Operator (VSO)** | Pulls static and dynamic secrets into EKS      |
| **Terraform**                    | Automates HCP Vault + Kubernetes + database setup |

## Prerequisites

- HCP account and Vault CLI access
- AWS account and CLI access
- Docker
- Terraform v1.13.3 or later
- Helm
- Kubectl
- Prisma AIRS API access + key (from Palo Alto Networks)
- Gemini API key
- psql (terminal-based front-end to PostgreSQL)

## Local Setup

## Provision basic infrastructure

To stand up the basic infrastructure, a few credentials must be configured:  

1. Copy `secrets.auto.tfvars.sample` and rename it to `secrets.auto.tfvars`.
 ```bash
    cd terraform
    cp secrets.auto.tfvars.sample secrets.auto.tfvars
   ```

1. Create an HCP account and follow the [authentication guide](https://registry.terraform.io/providers/hashicorp/hcp/latest/docs/guides/auth) to set up and retrieve your project ID, client ID and client secret. 

13. Fill in all required credentials in your `secrets.auto.tfvars`. Prisma AIRS requires API access; make sure you have a valid key. Refer to the [official Prisma AIRS documentation](https://docs.paloaltonetworks.com/ai-runtime-security/activation-and-onboarding/activate-your-ai-runtime-security-license/create-an-ai-instance-deployment-profile-in-csp) for setup details. If you don’t have it, you can continue without it, but be aware that some failures may occur and the UI experience will be limited.

1. Export your AWS access key and secret key in the console.  
1. Initialize Terraform:  
   ```bash
   terraform init
   ```
1. Build the infrastructure (HCP Vault Dedicated, RDS database, EKS cluster)
   ```bash
   terraform plan
   ```
   Reminder: psql commandline-tool in needed for this step.
1. Review the plan, then apply:
    ```bash
   terraform apply --auto-approve
   ```
At the end of this setup, Terraform provisions a major part of our core infrastructure: HCP Vault Dedicated cluster and a custom namespace. Learn about the benefits of Vault namespaces [here](https://developer.hashicorp.com/vault/tutorials/get-started-hcp-vault-dedicated/vault-namespaces). 

Explore your newly provisioned Vault cluster in both UI and CLI. Notice two namespaces: `admin` (default) and `trusted-ai-secrets` (custom).
- Go to the [HCP Console](https://portal.cloud.hashicorp.com).
- Navigate to **Vault Dedicated** > your cluster. Log into your cluster and explore the namespaces.

Optionally, you can log into the database and check if the data was loaded:
```bash
psql "host=your_rds_hostname port=5432 dbname=aiagentdb user=aiagent password=your_password sslmode=require"
```
Once connected, run 
```bash
 SELECT * FROM terraform_remote_state.states;
 ```
 This is out "fake" Terraform backend  - to be used by the infrastructure agent we're about to deploy.

## Dockerize both apps

Build Docker images and push them to Amazon ECR:

```sh
# Navigate to the first app directory
cd ../apps/ai-chatbot

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

For the second agent app,

```sh
# Navigate to the app directory
cd ../ai-agent

# Create the ECR repository (if it doesn't exist)
aws ecr create-repository --repository-name ai-agent-eks --region us-west-2

# Build the Docker image for amd64 architecture
docker buildx build --platform linux/amd64 -t ai-agent-eks:latest .

# Tag your image for ECR
docker tag ai-agent-eks:latest <aws_account_number>.dkr.ecr.us-west-2.amazonaws.com/ai-agent-eks:latest

# Tag & push your image
docker push <aws_account_number>.dkr.ecr.us-west-2.amazonaws.com/ai-agent-eks:latest
```
Note: The Docker build uses buildx only for Apple Silicon (M1/M2) Macs to enable multi-platform builds. On other architectures, buildx is not required.

## EKS and VSO Setup

### 1. Connect to Your EKS Cluster

For this section, navigate to the Kubernetes-related folder:

```sh
cd ../../k8s-manifests
```

```sh
aws eks update-kubeconfig --name ai-chatbot-cluster --region us-west-2
```

---

### 2. Install Vault Secrets Operator (VSO) with Helm

Follow the [HashiCorp Validated Pattern](https://developer.hashicorp.com/validated-patterns/vault/vault-kubernetes-auth#install-vault-secrets-operator-vso). Run all commands listed in the VSO install section. 
**Note:** When prompted for your Vault address, provide only the domain (remove `https://`). Use **public** Vault address.

---

### 3. Apply Kubernetes Manifests

Create the namespace:

```sh
kubectl apply -f namespace.yaml
```

The next manifest configures Kubernetes resources that allow both apps to securely authenticate with HashiCorp Vault and retrieve secrets. It creates service accounts, RBAC permissions, and Vault custom resources to sync secrets from Vault into Kubernetes, with automatic updates and deployment restarts when secrets change:

```sh
kubectl apply -f vault_auth.yaml
```

---

### 4. Configure Vault Kubernetes Auth

Export required values as environment variables:

```sh
export SA_TOKEN=$(kubectl get secret vault-auth-secret -n trusted-ai\
  -o jsonpath="{.data.token}" | base64 --decode)

export KUBERNETES_CA=$(kubectl get secret vault-auth-secret -n trusted-ai \
  -o jsonpath="{.data['ca\.crt']}" | base64 --decode)

export KUBERNETES_URL=$(kubectl config view --minify \
  -o jsonpath='{.clusters[0].cluster.server}')
```

---

### 5. Authenticate with Vault Namespace and configure Kubernetes Auth Method

- Go to the [HCP Console](https://portal.cloud.hashicorp.com).
- Navigate to **Vault Dedicated** > your cluster.
- Click **Generate Token** and copy it.

```sh
export VAULT_ADDR="<vault cluster url>"
vault login
```
Paste your namespace token when prompted.

```sh
vault write -namespace="admin/trusted-ai-secrets" auth/kubernetes/config \
  use_annotations_as_alias_metadata=true \
  token_reviewer_jwt="${SA_TOKEN}" \
  kubernetes_host="${KUBERNETES_URL}" \
  kubernetes_ca_cert="${KUBERNETES_CA}"
```
By authenticating Kubernetes Service Accounts to Vault, we establish a trusted identity that Vault can use to map to specific roles and policies. Once this setup is done, applications in Kubernetes will be able to authenticate to Vault transparently, without needing admin privileges themselves.

Why is Vault cluster admin token used in this step, and not namespace-level token? Writing to auth/kubernetes/config is considered a cluster-level operation (or at least requires permission to write to the auth mount), which is denied for namespace-scoped tokens.

---

## 6. RBAC for Vault Service Account

This manifest grants the `vault-sa` service account in the `trusted-ai` namespace read-only permissions on Kubernetes ServiceAccounts. It defines a `ClusterRole` with `get` and `list` verbs for ServiceAccounts and binds it to `vault-sa` through a `ClusterRoleBinding`.

```sh
oc apply -f vault-sa-rbac.yaml
```

---

### 7. Test Vault Access [OPTIONAL]

This step is entirely optional (just for checking and learning).

For this step, you'll need the namespace token, not the cluster admin token. You can retrieve it in your terminal from terraform outputs:

```sh
terraform -chdir=../terraform output -raw vault_trusted_ai_namespace_token
```

Is is the namespace-specific token. Use it to access our trusted-ai-secrets namespace in HCP Vault.

```sh
export VAULT_NAMESPACE=admin/trusted-ai-secrets
vault login
```
Paste your namespace token when prompted. Now run:

```sh
export APP_TOKEN=$(vault write -namespace="admin/trusted-ai-secrets" -field="token" \
  auth/kubernetes/login \
  role=ai-chatbot-role \
  jwt=$(kubectl create token -n trusted-ai chatbot))

VAULT_TOKEN=$APP_TOKEN vault kv get \
  -namespace="admin/trusted-ai-secrets" \
  -mount=kv chatbot
```

You should see the secrets stored in Vault for the chatbot app.

Why is namespace-level token used for this step? You are logging in to Vault via the Kubernetes auth method. The role=`ai-chatbot-role` is defined inside the namespace `admin/trusted-ai-secrets`. Vault generates a token scoped to that namespace (`admin/trusted-ai-secrets`) with the policies attached to that role. This is why you need the namespace-level token: the login is not at the cluster root level; it’s scoped to that namespace.

---

### 8. Deploy the Apps

Edit the AWS account in the image name if needed, then deploy:

```sh
oc apply -f deployment.yaml
```

This deployment should deploy use case #1 (chatbot), use case #2 (agent - helpful infrastructure assistant), and the Terraform MCP server used by app #2.

Check if pods are running:

```sh
oc get pods -n trusted-ai
```

You should see 3 pods: one for each app, and one for Terraform MCP.

---

### 9. Access the App

Check the load balancer service:

```sh
kubectl -n trusted-ai get svc ai-chatbot-svc
```
Copy EXTERNAL-IP value.

Open the http://EXTERNAL-IP/ai-chatbot in your browser (not https!)

Repeat the same for the second app:

```sh
kubectl -n trusted-ai get svc ai-agent-svc
```
Copy EXTERNAL-IP value.
Open the http://EXTERNAL-IP/ai-agent in your browser (not https!)

## Troubleshooting

### Verifying VSO

Check if secret was synced:

```sh
kubectl get secret chatbotkv -n trusted-ai
```

```sh
kubectl get secret agentkv -n trusted-ai
```


## Cleanup

Destroy all infra by running:

```sh
terraform destroy
```