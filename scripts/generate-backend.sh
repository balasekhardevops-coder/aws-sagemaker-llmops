#!/usr/bin/env bash
set -euo pipefail
# Run from repo root. Backend is intentionally gitignored.
# Preferred source: the state bucket recorded in the original bootstrap state.
if [[ -n "${STATE_BUCKET:-}" ]]; then
  BUCKET="$STATE_BUCKET"
elif [[ -f terraform/bootstrap/terraform.tfstate ]]; then
  BUCKET=$(terraform -chdir=terraform/bootstrap output -raw state_bucket_name)
else
  echo "Bootstrap local state was not included in the downloadable archive." >&2
  echo "Set STATE_BUCKET to your existing S3 state bucket, e.g.:" >&2
  echo "  STATE_BUCKET=your-existing-bucket bash scripts/generate-backend.sh" >&2
  exit 1
fi
[[ -n "$BUCKET" ]] || { echo "State bucket is empty" >&2; exit 1; }
aws s3api head-bucket --bucket "$BUCKET" >/dev/null
printf 'bucket = "%s"\n' "$BUCKET" > terraform/environments/dev/backend.hcl
echo "Generated dev backend config for verified existing S3 bucket (gitignored)."
