# Upgrading the uploaded flat Terraform repository to modules

This archive deliberately contains no `.git/`, `terraform.tfstate`, `tfplan`, `.terraform/`, or `backend.hcl`. The uploaded source included bootstrap local state; **preserve the original securely outside Git**. The S3 backend used by the dev environment is not modified.

## Safest update path for the existing Git checkout

1. Create a feature branch and preserve an encrypted backup of `terraform/bootstrap/terraform.tfstate` **outside** the checkout.
2. Copy the new `terraform/modules/`, updated `terraform/environments/dev/`, `scripts/`, `.github/`, `docs/` and README changes to your checkout.
3. **Remove the legacy flat resource files** (if they still exist) to avoid duplicate resources alongside module calls:

   ```bash
   rm -f terraform/environments/dev/{networking,security_groups,endpoints,iam,sagemaker,data_bucket}.tf
   ```

4. Stop tracking the generated backend file (leave its local copy untouched):

   ```bash
   git rm --cached terraform/environments/dev/backend.hcl 2>/dev/null || true
   ```

5. If there is no local `backend.hcl` already, generate it from the original bootstrap state:

   ```bash
   bash scripts/generate-backend.sh
   ```

   If you used a fresh extracted archive without bootstrap state, set `STATE_BUCKET=<your-existing-state-bucket>` explicitly (the script validates bucket access via `head-bucket`).
6. Check for previously created AWS resources **before** running apply:

   ```bash
   terraform -chdir=terraform/environments/dev init -backend-config=backend.hcl
   terraform -chdir=terraform/environments/dev state list
   terraform fmt -recursive terraform
   terraform -chdir=terraform/environments/dev validate
   terraform -chdir=terraform/environments/dev plan -out=tfplan
   ```

7. Review the plan. If flat resources had actually been applied, you **must migrate their Terraform state addresses** via `moved` blocks / `terraform state mv`. Import any manually created resources. Never approve a plan replacing a live SageMaker domain or VPC unexpectedly.
8. Do not push state files or a planned binary. Commit only source and lockfiles in a PR.

## Validation still required

The code has been structurally checked and checked against AWS/Terraform reference documentation. Terraform CLI is not available in the artifact-generation environment; therefore provider-level `terraform validate`, actual AWS planning, permissions, quota and SageMaker app startup **have not been executed**. Run these locally before treating the design as operational.
