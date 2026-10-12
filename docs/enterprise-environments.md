# Enterprise environment model

Use the manual Dev / QA / Prod infrastructure deployment workflow, with explicit region selection. No promotion and no automatic apply. See [Manual multi-region and production security](manual-multi-region-security.md).

Separate AWS accounts, GitHub OIDC roles, S3 remote-state buckets, approved environments, and Terraform root modules enforce isolation. Production Studio is off by default.
