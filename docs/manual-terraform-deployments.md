# Manually deploy Terraform

Run **GitHub Actions → Terraform Infrastructure - Manual**. Choose `target_environment` (`dev`, `qa`, or `prod`) and `aws_region` (`ap-south-1`, `us-east-1`, or `eu-west-1`). Review the plan artifact before approving the apply job. This does not promote any environment.

For state-key rules, required repository variables, approval setup, and security defaults, read [manual-multi-region-security.md](manual-multi-region-security.md).
