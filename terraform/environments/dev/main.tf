data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  data_bucket = "${local.name_prefix}-data-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

module "network" {
  source               = "../../modules/network"
  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security" {
  source      = "../../modules/security"
  name_prefix = local.name_prefix
  vpc_id      = module.network.vpc_id
  vpc_cidr    = module.network.vpc_cidr
  aws_region  = var.aws_region
}

module "endpoints" {
  source                     = "../../modules/endpoints"
  name_prefix                = local.name_prefix
  aws_region                 = var.aws_region
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  private_route_table_ids    = module.network.private_route_table_ids
  endpoint_security_group_id = module.security.endpoint_security_group_id
}

module "kms" {
  source = "../../modules/kms"
  name_prefix = local.name_prefix
}

module "data_bucket" {
  source       = "../../modules/s3-data"
  bucket_name  = local.data_bucket
  kms_key_arn  = module.kms.key_arn
}

module "iam" {
  source          = "../../modules/iam"
  name_prefix     = local.name_prefix
  data_bucket_arn = module.data_bucket.bucket_arn
  kms_key_arn     = module.kms.key_arn
}

module "studio" {
  source                   = "../../modules/studio"
  name_prefix              = local.name_prefix
  vpc_id                   = module.network.vpc_id
  private_subnet_ids       = module.network.private_subnet_ids
  domain_security_group_id = module.security.domain_security_group_id
  user_security_group_id   = module.security.user_security_group_id
  execution_role_arn       = module.iam.execution_role_arn
  kms_key_arn              = module.kms.key_arn
  user_profile_name        = var.user_profile_name
  jupyterlab_instance_type = var.jupyterlab_instance_type
  start_jupyterlab         = var.start_jupyterlab

  # Private endpoints and IAM must be ready before creating the domain.
  depends_on = [module.endpoints, module.security, module.iam]
}
