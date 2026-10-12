# aws-sagemaker-llmops

## SageMaker Studio Networking Modes

![SageMaker Studio Networking Modes](docs/images/sagemaker-networking-modes.png)

## Step 3 — SageMaker Studio VpcOnly via Terraform modules

This repository provisions a **private SageMaker Studio development foundation** with seven reusable modules in `terraform/modules/`. The `terraform/environments/dev/` folder is the thin root module that connects them.

Architecture: `network` (private VPC/subnets) → `security` (Studio/user/endpoint SGs) → `endpoints` (S3 + PrivateLink) and `kms`/`s3-data`/`iam` → `studio` (VpcOnly domain, IAM user profile, JupyterLab space). There is no NAT gateway or internet default route.

**Start here:** [Step 3 module guide](docs/step-3-modules.md) and [code walkthrough](docs/step-3-code-walkthrough.md), and [migration guide](docs/upgrade-from-flat-terraform.md).

```bash
# Once after bootstrap, from repository root:
bash scripts/generate-backend.sh
terraform -chdir=terraform/environments/dev init -backend-config=backend.hcl
terraform fmt -recursive terraform
terraform -chdir=terraform/environments/dev validate
terraform -chdir=terraform/environments/dev plan -out=tfplan
# Inspect the plan before applying it
terraform -chdir=terraform/environments/dev apply tfplan
bash scripts/verify-studio-vpconly.sh
```

**Security:** Do not commit or distribute Terraform state or plan files. `backend.hcl` is generated locally. `VpcOnly` limits Studio app networking but **does not by itself** make browser login private or automatically VPC-attach future training and inference jobs. See the guide for operational constraints and next hardening steps.

