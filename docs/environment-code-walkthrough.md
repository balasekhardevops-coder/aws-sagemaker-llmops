> **Current Dev note:** Dev retains its original root resource addresses for state continuity. The shared network, security, endpoints, S3 and IAM modules apply to QA/Prod; see [Repair & deployment runbook](REPAIR_AND_DEPLOY.md).

# Reading the multi-environment Terraform code

`terraform/environments/<env>/main.tf` is the **root module**. It calls `../../modules/network`, `security`, `endpoints`, `kms`, `s3-data`, `iam`, and optionally `studio`.

- `module.network.vpc_id`: read the child module's exported VPC ID; passes it to security/endpoints/studio modules. No hardcoded resource IDs.
- `module.security.endpoint_security_group_id`: passed to each interface VPC endpoint so TCP 443 inbound is allowed from SageMaker application SGs.
- `module.network.private_route_table_ids`: passed to S3 Gateway endpoint; it adds S3-prefix-list routes without NAT.
- `module.kms.key_arn`: connects storage encryption to IAM and SageMaker domain.
- `module.data_bucket.bucket_arn`: connects IAM permissions to the correct data bucket.
- `count = var.enable_studio ? 1 : 0`: optional Studio domain and JupyterLab space in QA/Prod. Disabled in Prod by default. Dev remains unchanged to avoid altering addresses.
- The `aws` provider in QA/Prod uses `allowed_account_ids` to prevent accidental cross-account deployment.
- Each environment has its own backend key; backend arguments do not accept Terraform variables, so the bucket comes from `terraform init -backend-config`.
- `on: workflow_call` creates a reusable GitHub Actions workflow. Apply job uses a GitHub Environment; **required reviewers must be configured in repository settings**.
- GitHub OIDC uses temporary credentials; plan and apply roles are different. `aws sts get-caller-identity` checks the intended account before planning/applying.

This update never modifies the existing Dev module call names or their state addresses. Keep local Dev overrides / changes if they are newer than this package.


Infrastructure **apply** is always manually triggered using `.github/workflows/terraform-infra-manual.yml`, selecting Dev, QA, or Prod. There is no promotion workflow and no automatic apply on push.
