# Repair summary (12 October 2026)

Changes are based on the uploaded `aws-sagemaker-llmops.tar(2).gz` snapshot. They have **not** been applied to AWS or pushed to GitHub.

## Corrected

1. Dev Terraform was declaring the same VPC, subnets, SGs, S3 bucket, IAM execution role, and VPC endpoints both at root and inside modules. It now retains the original dev root addresses, uses its existing flat resources, and adds only a KMS key and Studio domain via modules. This avoids implicit resource address migrations. The original AWS state still needs manual verification.
2. Dev Terraform outputs no longer reference missing `module.network`, `module.data_bucket`, or `module.endpoints` outputs. They reference actual dev resources.
3. SageMaker Studio gets a dedicated domain SG, NFS + Jupyter app traffic, and egress to S3/HTTPS endpoints. Dev keeps 5 interface endpoints by default (API, runtime, Studio, STS, CloudWatch Logs), avoiding accidental removal of the original five declared endpoints.
4. Identity Terraform now **looks up** the existing GitHub OIDC provider instead of attempting to create another account-global provider; its trust policies still distinguish branch-scoped plan from environment-scoped apply.
5. Identity Terraform creates/attaches AWS ReadOnlyAccess and explicit S3 backend policies plus an allowlisted infra apply IAM policy. This removes the missing-external-policy dependency, but production teams must tighten broadly scoped EC2/KMS/SageMaker write permissions and the read baseline.
6. Identity policy state key permissions now cover both the legacy dev Mumbai key and region-separated keys (including native `.tflock` files).
7. Manual GitHub Actions checks plan/apply role ARN shapes before assuming them; plan checks it can list the S3 backend prefix before running `terraform init`.
8. GitHub variables helper sets the actual repo variables consumed by the workflow rather than unused Environment-specific names. It refuses unrecognized role names. The helper creates the `terraform-ENV` GitHub Environment but does not pretend to install protection rules.
9. Added step-by-step admin bootstrap and recovery helper; no destructive or manual S3 lock cleanup is automated.
10. Terraform validation workflow includes bootstrap and identity root modules, alongside dev/qa/prod.
11. Updated `README.md`, added `docs/REPAIR_AND_DEPLOY.md` recovery runbook and `tests/test_repository_integrity.py` smoke tests.
12. Removed generated local `trust-policy.json` from the distributable project and added it to `.gitignore`.

## Verification performed in this environment

- Uploaded archive safely extracted and inspected.
- `bash -n` passed for all shell scripts.
- All three GitHub Actions YAML documents parsed.
- Six offline Python structural smoke tests passed.
- 55 `.tf` files passed a basic balanced-delimiter scan.

## Not validated here

- `terraform fmt`, `terraform init` and `terraform validate` could not run because Terraform is not installed in this execution container and binary download was unavailable.
- AWS API permissions, remote S3 state ownership and actual OIDC role assumption cannot be tested without AWS/GitHub credentials.
- Terraform plan changes or SageMaker endpoint/runtime behavior are not guaranteed until tested in the target account.

**Do not blindly run `apply`: review the runbook, real Terraform state and both the identity and infrastructure plans.**
