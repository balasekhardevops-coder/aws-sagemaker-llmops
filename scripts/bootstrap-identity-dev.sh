#!/usr/bin/env bash
set -euo pipefail
# Safe dev-only helper. Does NOT create an OIDC provider, roles, or modify AWS
# until the operator explicitly invokes 'apply' after reviewing 'plan'.
# Run from project root: bash scripts/bootstrap-identity-dev.sh init|plan|apply|publish
STEP="${1:-}"
ACCOUNT_ID="${ACCOUNT_ID:-758854589827}"
REGION="${AWS_REGION:-ap-south-1}"
STATE_BUCKET="${STATE_BUCKET:-sagemaker-llmops-tfstate-758854589827-ap-south-1}"
TF_DIR="terraform/identity"
if [[ ! "$STEP" =~ ^(init|plan|apply|publish)$ ]]; then
  echo 'Usage: bash scripts/bootstrap-identity-dev.sh init|plan|apply|publish' >&2; exit 2
fi
for bin in aws terraform; do command -v "$bin" >/dev/null || { echo "Missing $bin" >&2; exit 1; }; done
IDENTITY=$(aws sts get-caller-identity --output json)
ACTIVE_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
[[ "$ACTIVE_ACCOUNT" == "$ACCOUNT_ID" ]] || { echo 'Wrong AWS account' >&2; exit 1; }
if [[ $(aws sts get-caller-identity --query Arn --output text) == *:root ]]; then
  echo 'WARNING: using AWS root credentials; migrate to IAM Identity Center/admin role for daily operations.' >&2
fi
aws s3api head-bucket --bucket "$STATE_BUCKET" >/dev/null
PROVIDER="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$PROVIDER" >/dev/null || {
  echo 'GitHub OIDC provider missing: create once, then rerun.' >&2; exit 1;
}
# Explicit per-command variables mean no account-specific .tfvars needed.
COMMON=(-var="expected_account_id=${ACCOUNT_ID}" -var="environment=dev" -var="aws_region=${REGION}" -var="state_bucket=${STATE_BUCKET}")
case "$STEP" in
  init)
    terraform -chdir="$TF_DIR" init -reconfigure \
      -backend-config="bucket=${STATE_BUCKET}" \
      -backend-config="region=${REGION}" \
      -backend-config="key=identity/terraform.tfstate"
    ;;
  plan)
    terraform -chdir="$TF_DIR" validate
    terraform -chdir="$TF_DIR" plan "${COMMON[@]}" -lock-timeout=5m -out=identity.tfplan
    echo 'Review: terraform -chdir=terraform/identity show identity.tfplan'
    ;;
  apply)
    [[ -f "${TF_DIR}/identity.tfplan" ]] || { echo 'No saved reviewed plan. Run plan first.' >&2; exit 1; }
    terraform -chdir="$TF_DIR" apply -lock-timeout=5m identity.tfplan
    ;;
  publish)
    ENVIRONMENT=dev STATE_BUCKET="$STATE_BUCKET" BACKEND_REGION="$REGION" \
      bash scripts/setup-github-env.sh
    ;;
esac
