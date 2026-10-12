# AWS SageMaker LLMOps — Terraform-managed environments

- Shared modules in `terraform/modules/`.
- Independent Dev/QA/Prod root modules in `terraform/environments/`.
- `VpcOnly` networking for Studio when enabled.
- Production Studio defaults **off**.
- Manual infrastructure deployments only: Actions → **Terraform Infrastructure - Manual**, choose **environment** and **region**.
- Supported regions: `ap-south-1`, `us-east-1`, `eu-west-1`.
- Existing Dev Mumbai Terraform state is preserved as `dev/terraform.tfstate`.

See [manual deployment and security instructions](docs/manual-multi-region-security.md).

## SageMaker Studio Networking Modes

![SageMaker Studio Networking Modes](docs/images/sagemaker-networking-modes.png)
