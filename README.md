# terraform-vault-eks-prisma-airs
Secure, Terraform-deployed AI workloads on AWS EKS, with secrets managed via HCP Vault Dedicated and delivered using Vault Secrets Operator. Security guardrails provided by Prisma AIRS.

## Why This Matters

## What is deployed in this repo

| Component                        | Purpose                            |
| -------------------------------- | ---------------------------------- |
| **Python app (FastAPI)**           | Gemini-based chatbot with built-in guardrails by Palo Alto Networks Prisma AIRS            |
| **AWS EKS**         | Runs your app as a pod             |
| **HCP Vault Dedicated**          | Stores secrets in `kv-v2`          |
| **Vault Secrets Operator (VSO)** | Pulls secrets into EKS      |
| **Terraform**                    | Automates HCP Vault + Kubernetes setup |

## Prerequisites

- AWS account and CLI access
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