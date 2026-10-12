#!/usr/bin/env bash
set -euo pipefail
# Publish existing Terraform identity-role outputs to the actual repo variables
# referenced by .github/workflows/terraform-infra-manual.yml.
# Run AFTER: terraform -chdir=terraform/identity apply <reviewed-plan>
REPO="${REPO:-balasekhardevops-coder/aws-sagemaker-llmops}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
REGION="${BACKEND_REGION:-ap-south-1}"
STATE_BUCKET="${STATE_BUCKET:-sagemaker-llmops-tfstate-758854589827-ap-south-1}"
if [[ "$ENVIRONMENT" != dev && "$ENVIRONMENT" != qa && "$ENVIRONMENT" != prod ]]; then
  echo 'ENVIRONMENT must be dev, qa or prod' >&2; exit 1
fi
for bin in aws gh terraform; do command -v "$bin" >/dev/null || { echo "Missing $bin" >&2; exit 1; }; done
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PLAN_ROLE=$(terraform -chdir=terraform/identity output -raw plan_role_arn)
APPLY_ROLE=$(terraform -chdir=terraform/identity output -raw apply_role_arn)
EXPECTED_PREFIX="arn:aws:iam::${ACCOUNT_ID}:role/sagemaker-llmops-${ENVIRONMENT}-"
[[ "$PLAN_ROLE" == "${EXPECTED_PREFIX}terraform-plan" ]] || { echo "Unexpected plan role: $PLAN_ROLE" >&2; exit 1; }
[[ "$APPLY_ROLE" == "${EXPECTED_PREFIX}terraform-apply" ]] || { echo "Unexpected apply role: $APPLY_ROLE" >&2; exit 1; }
aws s3api head-bucket --bucket "$STATE_BUCKET" >/dev/null
aws iam get-role --role-name "sagemaker-llmops-${ENVIRONMENT}-terraform-plan" >/dev/null
aws iam get-role --role-name "sagemaker-llmops-${ENVIRONMENT}-terraform-apply" >/dev/null
SUFFIX=$(echo "$ENVIRONMENT" | tr '[:lower:]' '[:upper:]')
gh variable set "AWS_ACCOUNT_${SUFFIX}" --repo "$REPO" --body "$ACCOUNT_ID"
gh variable set "TF_STATE_BUCKET_${SUFFIX}" --repo "$REPO" --body "$STATE_BUCKET"
gh variable set "TF_BACKEND_REGION_${SUFFIX}" --repo "$REPO" --body "$REGION"
gh variable set "AWS_PLAN_ROLE_${SUFFIX}" --repo "$REPO" --body "$PLAN_ROLE"
gh variable set "AWS_APPLY_ROLE_${SUFFIX}" --repo "$REPO" --body "$APPLY_ROLE"
# The environment name must match the AWS OIDC trust policy. Required reviewers
# must be configured manually, and cannot be inferred from successful creation.
gh api --method PUT "repos/$REPO/environments/terraform-${ENVIRONMENT}" --silent
echo "Updated GitHub repository variables for $ENVIRONMENT."
echo "IMPORTANT: configure required reviewers for GitHub Environment terraform-${ENVIRONMENT} before deployment."
