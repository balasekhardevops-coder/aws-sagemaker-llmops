# Corrected AWS SageMaker LLMOps – recovery and deployment runbook

This archive repairs code; it **does not make changes to your AWS account or GitHub repo automatically**.

## 0. Before running anything

- Use an administrative **IAM Identity Center / assumed admin role**, rather than `arn:aws:iam::758854589827:root` credentials.
- S3 state bucket (already present): `sagemaker-llmops-tfstate-758854589827-ap-south-1`.
- GitHub OIDC provider (already present): `arn:aws:iam::758854589827:oidc-provider/token.actions.githubusercontent.com`.
- The previously hand-created `terraform-plan` role is **NOT** the identity Terraform role. Do not import this differing name into the Terraform role address.
- The Terraform-managed role names are `sagemaker-llmops-dev-terraform-plan` and `sagemaker-llmops-dev-terraform-apply`.
- Do **not** delete state objects or `.tflock` manually, call `terraform force-unlock` while a job is running, or run `terraform apply` before reading the plan.
- You must verify what resources already exist: `aws s3api list-objects-v2 --bucket sagemaker-llmops-tfstate-758854589827-ap-south-1 --prefix dev/`.

## 1. Verify prerequisites

From the project root in Git Bash:

```bash
aws sts get-caller-identity
aws iam list-open-id-connect-providers
aws s3api head-bucket --bucket sagemaker-llmops-tfstate-758854589827-ap-south-1
terraform version
gh auth status
```

GitHub repository owner and repository IDs are pinned in `terraform/identity/main.tf` to the current project's owner/repository. Confirm against the GitHub API in case repository ownership changes:

```bash
gh api repos/balasekhardevops-coder/aws-sagemaker-llmops/actions/oidc/customization/sub
```

Verify the `sub_claim_prefix` corresponds to `repo:balasekhardevops-coder@277724570/aws-sagemaker-llmops@1415110746`, then use the exact branch/environment suffixes in the IAM trust policies. The repository was created after the July 2026 immutable-subject change.

## 2. Bootstrap the identity stack from your local administrative session

```bash
bash scripts/bootstrap-identity-dev.sh init
bash scripts/bootstrap-identity-dev.sh plan
terraform -chdir=terraform/identity show identity.tfplan
```

Review output for only the two intended role names, IAM role policies, attachments, and no unexpected deletes. The existing OIDC provider is **read as a data source**, so it must already exist and does not require a Terraform import. It is account-global; it is intentionally not recreated by each environment identity state.

After review:

```bash
bash scripts/bootstrap-identity-dev.sh apply
bash scripts/bootstrap-identity-dev.sh publish
```

Note: identity Terraform uses `identity/terraform.tfstate`, separate from the infrastructure state `dev/terraform.tfstate`.

## 3. GitHub approval / variables

Confirm the repo variable values:

```bash
gh variable list --repo balasekhardevops-coder/aws-sagemaker-llmops
```

The workflow consumes `AWS_ACCOUNT_DEV`, `TF_STATE_BUCKET_DEV`, `TF_BACKEND_REGION_DEV`, `AWS_PLAN_ROLE_DEV`, and `AWS_APPLY_ROLE_DEV`. Both role values must be real ARNs, **not AWS CLI commands or placeholders**.

The apply job uses **GitHub Environment `terraform-dev`**. Configure its required reviewers, allowed branches (main) and protection rules under repository **Settings → Environments → terraform-dev**. Merely creating the environment does not enable approvals. If your GitHub plan prevents required reviewers, do **not** claim a protected production approval; configure an alternate controlled deployment approval mechanism before production use.

## 4. Dev infrastructure (existing state)

**Important:** Dev retains the original root-level resource addresses (`aws_vpc.llmops`, `aws_subnet.private`, existing S3/SGs/endpoints/roles) to avoid destroying an existing VPC by silently moving it into modules. KMS, Studio domain and dedicated domain SG are new. QA/Prod continue to use shared modules.

Check remote state and plan BEFORE launching the GitHub workflow:

```bash
cd terraform/environments/dev
terraform init -reconfigure -backend-config="bucket=sagemaker-llmops-tfstate-758854589827-ap-south-1" \
  -backend-config="region=ap-south-1" -backend-config="key=dev/terraform.tfstate"
terraform state list
terraform plan -var="expected_account_id=758854589827" -var="aws_region=ap-south-1" -out=tfplan
terraform show tfplan
```

If the state is empty but AWS resources already exist, STOP and import them at the correct existing root addresses; do not deploy duplicates. Do not replace an existing VPC or S3 bucket without an explicit migration and backups.

## 5. Remote manual deployment

Actions → **Terraform Infrastructure - Manual** → `dev`, `ap-south-1`. Plan job uses branch-scoped `sagemaker-llmops-dev-terraform-plan`, locks the state in S3; apply uses environment-scoped `sagemaker-llmops-dev-terraform-apply`. Both have backend access and the plan/apply permissions created by identity Terraform. `ReadOnlyAccess` is an AWS-wide read baseline. Apply uses a project write-action allowlist but some EC2/SageMaker/KMS actions remain `Resource = "*"` due AWS authorisation behavior: **treat as a training-lab starting point**, not an independently audited enterprise least-privilege policy.

## 6. If errors remain

- **OIDC assume failed:** compare `gh api repos/.../actions/oidc/customization/sub` with IAM `:sub`; plan must be `...:ref:refs/heads/main`, apply `...:environment:terraform-dev`.
- **S3 `HeadObject` 403:** verify plan role ARN, backend bucket, `s3:ListBucket`, `s3:GetObject`, any bucket explicit denies/SCPs, and missing object handling. State absent plus missing ListBucket can also appear as 403. Check with an authorized admin session.
- **Lock 412:** another process may hold the `.tflock`; inspect other workflows and lock metadata. Do not force-unlock an active writer.
- **`NoSuchEntity`:** role names are prefixed; the old manually created `terraform-plan` is a separate unmanaged role.
- **AWS service AccessDenied after backend succeeds:** record missing action/resource in IAM policy and scope the fix. Avoid attaching `AdministratorAccess`.
- **Insufficient SageMaker VPC-only connectivity:** check endpoint selection, Studio/DNS/NFS ports, and required service endpoints; no NAT means no general internet/pip/Git clone from Studio.

## 7. Before using for production

Keep different AWS accounts for Dev/QA/Prod; audit region-specific IAM scopes, IAM permission boundaries, SCPs, artifact exposure, environment protection, state encryption, and endpoint spend. Bootstrap OIDC provider once per AWS account, not once per environment. GitHub workflow's saved Terraform plan artifact can contain sensitive data; use private repos, restrict artifact access and retention, or adopt a secure private plan store.
