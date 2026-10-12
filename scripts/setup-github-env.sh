#!/usr/bin/env bash
set -euo pipefail

read -rp "GitHub repository (owner/repo): " REPO

for ENV in dev qa prod; do
  echo "================================"
  echo "Configuring environment: $ENV"
  echo "================================"

  read -rp "AWS Account ID: " ACCOUNT_ID
  read -rp "Terraform State Bucket: " BUCKET
  read -rp "Backend AWS Region [ap-south-1]: " BACKEND_REGION
  BACKEND_REGION=${BACKEND_REGION:-ap-south-1}

  read -rp "Terraform Plan Role Name [terraform-plan]: " PLAN_ROLE_NAME
  PLAN_ROLE_NAME=${PLAN_ROLE_NAME:-terraform-plan}

  read -rp "Terraform Apply Role Name [terraform-apply]: " APPLY_ROLE_NAME
  APPLY_ROLE_NAME=${APPLY_ROLE_NAME:-terraform-apply}

  PLAN_ROLE="arn:aws:iam::${ACCOUNT_ID}:role/${PLAN_ROLE_NAME}"
  APPLY_ROLE="arn:aws:iam::${ACCOUNT_ID}:role/${APPLY_ROLE_NAME}"

  # Create GitHub Environment
  gh api \
    --method PUT \
    "repos/${REPO}/environments/${ENV}" \
    --silent

  # Configure environment variables
  gh variable set ACCOUNT_ID \
    --repo "$REPO" --env "$ENV" --body "$ACCOUNT_ID"

  gh variable set BUCKET \
    --repo "$REPO" --env "$ENV" --body "$BUCKET"

  gh variable set BACKEND_REGION \
    --repo "$REPO" --env "$ENV" --body "$BACKEND_REGION"

  gh variable set PLAN_ROLE \
    --repo "$REPO" --env "$ENV" --body "$PLAN_ROLE"

  gh variable set APPLY_ROLE \
    --repo "$REPO" --env "$ENV" --body "$APPLY_ROLE"

  echo "$ENV configured successfully."
done