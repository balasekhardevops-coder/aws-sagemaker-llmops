> **Recovery note:** See [Repair & deployment runbook](REPAIR_AND_DEPLOY.md) for the corrected Dev role/identity bootstrap and state-preserving Dev root.

# Manual Dev, QA, Prod Terraform deployments in three regions

## Select environment and region
Actions → **Terraform Infrastructure - Manual** → Run workflow.
Choose `dev`, `qa`, or `prod`, plus `ap-south-1` (Mumbai), `us-east-1` (N. Virginia), or `eu-west-1` (Ireland).
There is **no promotion** and **no automatic apply**. The workflow checks out only `main`.

Each environment uses its own AWS account and IAM OIDC plan/apply roles. Create GitHub Environments `terraform-dev`, `terraform-qa`, `terraform-prod`; configure required reviewers for QA and Prod, branch restriction to `main`, and prevent self-review where supported. **Simply naming an Environment does not enforce review.** The plan job runs first; the Environment approval gates the separate apply job.

## Required repository variables

| Variable | Example / use |
| --- | --- |
| `AWS_ACCOUNT_DEV`, `AWS_ACCOUNT_QA`, `AWS_ACCOUNT_PROD` | Different 12-digit AWS account IDs |
| `TF_STATE_BUCKET_DEV`, `TF_STATE_BUCKET_QA`, `TF_STATE_BUCKET_PROD` | Existing versioned, encrypted backend bucket in the corresponding account |
| `TF_BACKEND_REGION_DEV`, `TF_BACKEND_REGION_QA`, `TF_BACKEND_REGION_PROD` | S3 backend bucket region, independently of deployment region; e.g. `ap-south-1` |
| `AWS_PLAN_ROLE_DEV`, `AWS_PLAN_ROLE_QA`, `AWS_PLAN_ROLE_PROD` | Plan IAM role ARN for each account |
| `AWS_APPLY_ROLE_DEV`, `AWS_APPLY_ROLE_QA`, `AWS_APPLY_ROLE_PROD` | Apply IAM role ARN for each account |

Create the S3 backend buckets and OIDC roles **before** running the workflow. Restrict S3 backend IAM permissions to the relevant state key and `.tflock` object. Plan roles need remote-state locking and sufficient read/refresh permissions; apply roles require narrowly scoped infrastructure permissions and `iam:PassRole` only for approved roles. Never attach AdministratorAccess as a permanent production fix. Use branch protection / CODEOWNERS for Terraform and workflow changes. In production, protect workflow definitions and roles against edits by the same person who authorizes deployment.

## State isolation: critical for region selection

- `dev` + `ap-south-1`: `dev/terraform.tfstate` **(unchanged from existing live Dev)**.
- `dev` + `us-east-1`: `dev/us-east-1/terraform.tfstate`.
- `dev` + `eu-west-1`: `dev/eu-west-1/terraform.tfstate`.
- `qa` / `prod`: `${env}/${region}/terraform.tfstate`, e.g. `prod/eu-west-1/terraform.tfstate`.

Backend S3 bucket REGION is not necessarily the region where Terraform creates SageMaker resources. The workflow explicitly sets both. **Do not move the existing Dev state** without a separately planned state migration. If you ever run QA/Prod locally, supply all three backend settings explicitly.

## Production security defaults

- `enable_studio = false` — does **not** create SageMaker Studio, JupyterLab, the Studio execution role, its SGs, or Studio VPC endpoints. `network`, `kms`, and `s3-data` remain, ready for future jobs. Production workloads will have their own IAM and network modules in later phases.
- `start_jupyterlab = false` in every environment.
- Private subnets have no internet default route.
- Bucket public access is blocked, TLS required, SSE-KMS enabled, versioning enabled, prevent_destroy set.
- KMS uses rotation and prevent_destroy.
- Plan job **fails on any proposed Terraform delete or replacement in Prod**; to permit such a migration requires a reviewed code and policy change, not merely a different dropdown value.
- AWS account ID is checked in both jobs and in the Terraform AWS provider.
- Production apply is gated behind `terraform-prod` approval rules (must be configured on GitHub).

## Caveats

1. The initial Prod account provisions networking, KMS, and S3 only. Future model hosting will require additional private endpoint/IAM/network definitions, not just a Studio toggle.
2. The first QA/Prod deployments must have verified service availability and quotas in each selected region.
3. This workflow uses `hashicorp/setup-terraform@v3`, `aws-actions/configure-aws-credentials@v4`, `actions/checkout@v4`, and artifact actions v4. For production, pin these to audited **commit SHAs** and update on an approved schedule.
4. The current GitHub repo is public. The workflow refuses Production deployment until it is moved to a private infrastructure repository. Private repositories require an eligible GitHub plan for enforced required-reviewer deployment protections; check your account plan. Saved Terraform plans and human-readable reviews may contain secrets. Restrict Actions artifacts and retain them only one day. Do not print plan contents in public PR comments.
5. JupyterLab, interface endpoints, EBS, KMS and S3 incur usage charges. No Studio means no Studio app compute charges, but S3/KMS still cost.
6. The OIDC trust policy supplied with the existing project must match the **actual subject token** issued to your repository and have separate main-branch plan versus protected-environment apply conditions.

## Local verification

```bash
terraform fmt -recursive terraform
for env in dev qa prod; do
  terraform -chdir="terraform/environments/${env}" init -backend=false
  terraform -chdir="terraform/environments/${env}" validate
done
```

**Don't run `terraform apply` against an existing environment until you've reviewed the exact plan and checked Terraform resource addresses and account/region/state.**
