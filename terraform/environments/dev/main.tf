# Dev retains the original root-level resource addresses for safe state continuity.
# Do not add network/security/endpoints/s3-data/iam modules here without moved
# blocks and a reviewed state migration plan.
data "aws_caller_identity" "current" {}

locals {
  name_prefix = var.aws_region == "ap-south-1" ? "${var.project_name}-${var.environment}" : "${var.project_name}-${var.environment}-${var.aws_region}"
}

# KMS key and Studio were not present in the legacy flat Dev stack.
module "kms" {
  source      = "../../modules/kms"
  name_prefix = local.name_prefix
}

module "studio" {
  source                   = "../../modules/studio"
  name_prefix              = local.name_prefix
  vpc_id                   = aws_vpc.llmops.id
  private_subnet_ids       = [for k in sort(keys(aws_subnet.private)) : aws_subnet.private[k].id]
  domain_security_group_id = aws_security_group.studio_domain.id
  user_security_group_id   = aws_security_group.studio.id
  execution_role_arn       = aws_iam_role.studio_execution.arn
  kms_key_arn              = module.kms.key_arn
  user_profile_name        = var.user_profile_name
  jupyterlab_instance_type = var.jupyterlab_instance_type
  start_jupyterlab         = var.start_jupyterlab

  depends_on = [aws_vpc_endpoint.s3, aws_vpc_endpoint.interface, aws_iam_role_policy.studio_data, aws_iam_role_policy.studio_kms]
}

module "training_ecr" {
  source = "../../modules/ecr"

  repository_name = "sagemaker-llmops-dev-training"
  environment     = "dev"
}