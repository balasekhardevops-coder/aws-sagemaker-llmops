# Step 3 — Modular SageMaker Studio VpcOnly

## What belongs where

* `terraform/environments/dev/` is the **root module**: backend and provider are configured here, and `main.tf` calls child modules.
* `terraform/modules/network/` creates two private subnets and their route tables; no NAT or IGW.
* `terraform/modules/security/` defines separate domain, user and interface endpoint security groups, including the necessary NFS and Jupyter app ports.
* `terraform/modules/endpoints/` provisions private S3 Gateway and interface endpoints: SageMaker API, SageMaker Runtime, Studio, STS and CloudWatch Logs.
* `terraform/modules/kms/` creates a customer-managed encryption key, rotated annually, and protected against deletion.
* `terraform/modules/s3-data/` creates a versioned S3 data bucket with SSE-KMS, public access block, and TLS-only policy.
* `terraform/modules/iam/` creates an execution role with project bucket/KMS access and limited SageMaker describe operations.
* `terraform/modules/studio/` creates the IAM-authenticated `VpcOnly` domain, user profile, private JupyterLab space and optional running app.

## Bootstrap stays separate

Do not alter the existing `terraform/bootstrap` configuration. Keep its local state safe. The development root module uses the Step 2 S3 backend.

## Run in Git Bash from repository root

```bash
bash scripts/generate-backend.sh # or set STATE_BUCKET for a clean archive
terraform -chdir=terraform/environments/dev init -backend-config=backend.hcl
terraform -chdir=terraform/environments/dev fmt -recursive
terraform -chdir=terraform/environments/dev validate
terraform -chdir=terraform/environments/dev plan -out=tfplan
terraform -chdir=terraform/environments/dev apply tfplan
```

To run a JupyterLab app only when needed:

```bash
terraform -chdir=terraform/environments/dev apply -var='start_jupyterlab=true'
terraform -chdir=terraform/environments/dev apply -var='start_jupyterlab=false'
```

## Critical notes

1. `VpcOnly` governs the Studio **application network**. A public AWS Console login is not automatically disabled; require private browser access separately if mandated.
2. No NAT means no direct public PyPI, GitHub or Hugging Face access from JupyterLab. Mirror needed packages/artifacts into private S3 or use approved egress.
3. SageMaker-created EFS mount-target security groups may require specific rules. Verify NFS mount after domain creation before declaring the system operational.
4. Studio execution role can read/write only the project bucket and use the project KMS key. It does not yet have full training, model-registry or deployment permissions. Those should be defined as **separate roles** in later modules.
5. For real production, add CloudTrail, VPC Flow Logs, endpoint policies, IAM Identity Center onboarding, continuous policy scanning, backup/retention, account separation, and an internal package mirror.
6. VPC interface endpoints, KMS, EBS and EFS can incur ongoing charges with JupyterLab stopped. There is no automatic shutdown of endpoints.
7. Some provider/API settings are sensitive to AWS provider versions or the selected SageMaker images. Run `terraform validate`, `plan`, and an actual restricted environment smoke test before deployment approval.
8. State from existing resources must not be blindly moved. If resources were previously created in the same dev root module, use `moved` blocks or `terraform state mv` as appropriate; if created outside Terraform, import them.

## Verify

```bash
DOMAIN_ID=$(terraform -chdir=terraform/environments/dev output -raw sagemaker_domain_id)
aws sagemaker describe-domain --domain-id "$DOMAIN_ID" --region ap-south-1 --query '{Network:AppNetworkAccessType,Status:Status}'
```

Expect `Network` to be `VpcOnly` and `Status` eventually to be `InService`.


**Updated SG/IAM requirements:** The domain/user groups include rules for TCP 8192-65535 application communication, and the execution role includes KMS `CreateGrant` for customer-managed domain encryption. Verify the actual EFS mount-target security group after domain creation. See [code walkthrough](step-3-code-walkthrough.md).
