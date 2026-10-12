# Step 3 — SageMaker Studio VpcOnly

> This earlier flat-root deployment guide has been superseded by the modular implementation.
> Follow [Step 3 Modules](step-3-modules.md) and [Code Walkthrough](step-3-code-walkthrough.md).

The code lives in `terraform/modules/{network,security,endpoints,kms,s3-data,iam,studio}`.
The `terraform/environments/dev` root only composes these reusable modules and configures the existing S3 backend.
