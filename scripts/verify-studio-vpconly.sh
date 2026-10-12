#!/usr/bin/env bash
set -euo pipefail
TF_DIR="terraform/environments/dev"
REGION="${AWS_REGION:-ap-south-1}"
DOMAIN_ID=$(terraform -chdir="$TF_DIR" output -raw sagemaker_domain_id)
VPC_ID=$(terraform -chdir="$TF_DIR" output -raw vpc_id)
NETWORK=$(aws sagemaker describe-domain --region "$REGION" --domain-id "$DOMAIN_ID" --query AppNetworkAccessType --output text)
[[ "$NETWORK" == VpcOnly ]] || { echo "Expected VpcOnly, got $NETWORK" >&2; exit 1; }
DEFAULT_ROUTES=$(aws ec2 describe-route-tables --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[].Routes[].DestinationCidrBlock' --output text)
if grep -q '0\.0\.0\.0/0' <<< "$DEFAULT_ROUTES"; then
  echo 'Found an IPv4 default route; inspect associated route tables' >&2; exit 1
fi
aws ec2 describe-vpc-endpoints --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'VpcEndpoints[].{Service:ServiceName,State:State,Type:VpcEndpointType}' --output table
for name in sagemaker.api sagemaker.runtime sts logs; do
  COUNT=$(aws ec2 describe-vpc-endpoints --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=service-name,Values=com.amazonaws.${REGION}.${name}" "Name=vpc-endpoint-state,Values=available" \
    --query 'length(VpcEndpoints)' --output text)
  [[ "$COUNT" -ge 1 ]] || { echo "Missing usable private endpoint: $name" >&2; exit 1; }
done
S3=$(aws ec2 describe-vpc-endpoints --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=service-name,Values=com.amazonaws.${REGION}.s3" "Name=vpc-endpoint-state,Values=available" \
  --query 'length(VpcEndpoints)' --output text)
[[ "$S3" -ge 1 ]] || { echo 'S3 VPC endpoint missing' >&2; exit 1; }
echo "PASS: VpcOnly $DOMAIN_ID with private endpoints and no IPv4 default route."
echo 'Still verify Studio DNS, TCP 2049, app-to-app communication, IPv6 routes and browser connectivity.'
