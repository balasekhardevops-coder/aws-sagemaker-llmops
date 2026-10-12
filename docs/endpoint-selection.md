# Dev VPC endpoints — opt-in selection

By default, `terraform/environments/dev` enables the SageMaker API and Runtime **interface** endpoints. The S3 **Gateway** endpoint is always created and associated with the private route tables.

To enable private Studio service access or SDK remote-training dependencies, set for example:

```hcl
enabled_interface_endpoints = ["api", "runtime", "studio", "sts", "logs"]
```

in a `.tfvars` file supplied to `terraform plan/apply`. If accessing Studio privately from your VPC, include `studio`; SDK workflows that require STS and CloudWatch Logs should include `sts` and `logs`. Endpoint creation does not itself guarantee browser reachability, authorization, or ECR/package access.

**Change caution:** If existing endpoints were already created in remote Terraform state, reducing the set will plan to destroy removed endpoints; review the plan and impact. Interface endpoints have hourly cost per provisioned AZ. This module deliberately does not add NAT or internet routes.
