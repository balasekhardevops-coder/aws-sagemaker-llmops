#!/usr/bin/env bash
set -euo pipefail
# Run after successful Terraform apply from the repository root.
TF_DIR="terraform/environments/dev"
REGION="${AWS_REGION:-ap-south-1}"
DOMAIN_ID=$(terraform -chdir="$TF_DIR" output -raw sagemaker_domain_id)
VPC_ID=$(terraform -chdir="$TF_DIR" output -raw vpc_id)
NETWORK=$(aws sagemaker describe-domain --region "$REGION" --domain-id "$DOMAIN_ID" --query AppNetworkAccessType --output text)
[[ "$NETWORK" == "VpcOnly" ]] || { echo "Expected VpcOnly, got $NETWORK" >&2; exit 1; }
DEFAULT_ROUTES=$(aws ec2 describe-route-tables --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[].Routes[].DestinationCidrBlock' --output text)
if grep -q '0\.0\.0\.0/0' <<< "$DEFAULT_ROUTES"; then
  echo "Found an IPv4 default route; inspect all route table associations." >&2
  exit 1
fi
EP_STATUS=$(aws ec2 describe-vpc-endpoints --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" --query 'VpcEndpoints[].State' --output text)
EP_COUNT=$(wc -w <<< "$EP_STATUS" | tr -d ' ')
[[ "$EP_COUNT" -ge 6 ]] || { echo "Expected at least six VPC endpoints; saw $EP_COUNT" >&2; exit 1; }
if grep -Eqi 'pending|failed|deleting|rejected|expired' <<< "$EP_STATUS"; then
  echo "Some endpoints are not ready: $EP_STATUS" >&2
  exit 1
fi
aws ec2 describe-vpc-endpoints --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" --query 'VpcEndpoints[].{Service:ServiceName,State:State,Type:VpcEndpointType}' --output table
echo "PASS: VpcOnly domain $DOMAIN_ID; no IPv4 default routes; $EP_COUNT endpoints checked."
echo "Still verify DNS, interface SG rules, EFS TCP 2049, notebook access and lack of IPv6 egress."
