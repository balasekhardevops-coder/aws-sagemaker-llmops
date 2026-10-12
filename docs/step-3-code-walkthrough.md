> **Current Dev note:** Dev retains its original root resource addresses for state continuity. The shared network, security, endpoints, S3 and IAM modules apply to QA/Prod; see [Repair & deployment runbook](REPAIR_AND_DEPLOY.md).

# Step 3 — Code walkthrough: modular Terraform + SageMaker `VpcOnly`

## Why modules?

The `dev` directory is a **root module**. It has a backend and AWS provider, and it calls **child modules**. Child modules contain actual AWS resource blocks and accept `var.*` values; they return `output` values accessible as `module.NAME.OUTPUT`. All modules called by this Dev root share the **one** state key `dev/terraform.tfstate`.

## Resource ownership by module

| Module | File | Resources | Inputs/outputs |
|---|---|---|---|
| `network` | `modules/network/main.tf` | VPC, 2 private subnets, 2 route tables + associations | Input CIDRs; outputs `vpc_id`, `private_subnet_ids`, `private_route_table_ids` |
| `security` | `modules/security/main.tf` | Domain SG, user SG, endpoints SG, explicit ingress/egress rules | Input VPC; outputs SG IDs |
| `endpoints` | `modules/endpoints/main.tf` | S3 gateway endpoint; SageMaker API, Runtime, Studio, STS, Logs interface endpoints | Input subnets, SG, routes; outputs endpoint IDs |
| `kms` | `modules/kms/main.tf` | Customer-managed KMS key + alias; rotation, deletion guard | Input name; output `key_arn` |
| `s3-data` | `modules/s3-data/main.tf` | Versioned, encrypted bucket; public-access block; TLS-only bucket policy | Inputs bucket name, KMS key; output bucket ARN |
| `iam` | `modules/iam/main.tf` | SageMaker execution IAM role + constrained S3/KMS/SageMaker permissions | Inputs bucket ARN, key ARN; output `execution_role_arn` |
| `studio` | `modules/studio/main.tf` | SageMaker Studio domain (`VpcOnly`), user profile, private JupyterLab space and optional app | Inputs VPC/subnets/SGs/role/KMS, `start_jupyterlab` |

## Flow of values

`module.network.vpc_id` is an **output** of the network module, passed to the security, endpoints, and Studio modules as **inputs**. Similarly, `module.security.endpoint_security_group_id` goes to the endpoints module, while `module.iam.execution_role_arn` is passed to Studio.

Example:

```hcl
module "network" {
  source = "../../modules/network"
  name_prefix = local.name_prefix
  vpc_cidr = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security" {
  source = "../../modules/security"
  name_prefix = local.name_prefix
  vpc_id = module.network.vpc_id
  vpc_cidr = module.network.vpc_cidr
  aws_region = var.aws_region
}
```

The root defines the relationships; Terraform builds a dependency graph and provisions resources in dependency order.

## Security group rules — the essential ports

- **TCP 443:** Studio user/domain apps → interface endpoint ENIs (SageMaker APIs, STS, CloudWatch). Egress on the Studio SG, matching ingress on endpoint SG.
- **TCP 2049:** NFS from Studio apps to the SageMaker-managed EFS mount targets. The relevant EFS target SG must allow it; verify once the domain exists.
- **TCP 8192–65535:** Required connections between SageMaker apps. We allow self-referencing rules for the user SG and limited domain↔user SG communication (without a broad domain SG self rule).
- **S3 gateway:** No SG on the gateway endpoint. Studio SG permits outbound TCP 443 to the region's S3 managed prefix list; the gateway endpoint adds the route.
- **No 0.0.0.0/0 outbound traffic:** We use standalone security group rules instead of a wildcard outbound rule.

SGs control permitted network connections; IAM controls whether the AWS action is authorized. Routing/endpoint DNS must also work.

## SageMaker domain, space, and app

- `aws_sagemaker_domain` is the main Studio environment; `app_network_access_type="VpcOnly"` directs Studio app traffic through your subnets.
- `aws_sagemaker_user_profile` creates a named developer profile in the domain, not an IAM user.
- `aws_sagemaker_space` creates persistent JupyterLab space and 20 GiB EBS storage.
- `aws_sagemaker_app` starts computing only when `start_jupyterlab=true`; idle shutdown is configured at domain level.

## IAM and encryption

SageMaker assumes its execution role. That role can access only the project S3 data bucket, its KMS key, and a small set of SageMaker listing/describe APIs. `kms:CreateGrant` is included for domain volumes using a customer-managed KMS key (per SageMaker docs). The Terraform operator needs additional deploy-time permissions such as `iam:PassRole`.

S3 state and application data are **different buckets**. Never rename or delete the bootstrap remote-state bucket while active environments use it.

## No-NAT tradeoff

Notebooks cannot directly install from public PyPI or clone GitHub from the private subnet. Stage approved dependencies/models in S3 or implement controlled egress/private package mirrors in later phases. Interface endpoints have ongoing charges, even with JupyterLab compute off.

## Operational checks / limitations

This is a **production-oriented development foundation**, not proof of production readiness. Validate endpoint service availability, SG associations for EFS, app startup, notebook traffic, quotas and private DNS in your AWS account. For production, add account separation, approval gates, CloudTrail/Flow Logs, explicit endpoint policies, stronger identity controls, customer-managed package distribution, and VPC configuration for later Processing/Training/Endpoints.

See [AWS VpcOnly requirements](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-updated-and-internet-access.html) and [Terraform SageMaker domain schema](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_domain).

## Applying to existing infrastructure

Before applying, inspect the existing state: `terraform -chdir=terraform/environments/dev state list`. If a flat configuration **has already been applied**, moving resources into modules changes Terraform addresses; add `moved` blocks or use `terraform state mv` to avoid destroying/recreating resources. Do **not** apply a plan showing unexpected SageMaker/domain replacement.
