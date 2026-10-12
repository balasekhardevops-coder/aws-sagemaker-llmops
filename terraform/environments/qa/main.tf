data "aws_caller_identity" "current" {}

locals {
  # Distinct resource names across AWS regions; IAM names are account-global.
  name_prefix = "${var.project_name}-${var.environment}-${var.aws_region}"
  data_bucket = "${local.name_prefix}-data-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

module "network" {
  source               = "../../modules/network"
  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Studio-only security, IAM role, and endpoint ENIs are not deployed in Prod
# unless Studio is deliberately enabled. Reuse other modules for training later.
module "security" {
  count       = var.enable_studio ? 1 : 0
  source      = "../../modules/security"
  name_prefix = local.name_prefix
  vpc_id      = module.network.vpc_id
  vpc_cidr    = module.network.vpc_cidr
  aws_region  = var.aws_region
}

module "endpoints" {
  count                       = var.enable_studio ? 1 : 0
  source                      = "../../modules/endpoints"
  name_prefix                 = local.name_prefix
  aws_region                  = var.aws_region
  vpc_id                      = module.network.vpc_id
  private_subnet_ids          = module.network.private_subnet_ids
  private_route_table_ids     = module.network.private_route_table_ids
  endpoint_security_group_id  = try(module.security[0].endpoint_security_group_id, null)
  enabled_interface_endpoints = var.enabled_interface_endpoints
}

module "kms" {
  source      = "../../modules/kms"
  name_prefix = local.name_prefix
}

module "data_bucket" {
  source      = "../../modules/s3-data"
  bucket_name = local.data_bucket
  kms_key_arn = module.kms.key_arn
}

module "iam" {
  count           = var.enable_studio ? 1 : 0
  source          = "../../modules/iam"
  name_prefix     = local.name_prefix
  data_bucket_arn = module.data_bucket.bucket_arn
  kms_key_arn     = module.kms.key_arn
}

module "studio" {
  count                    = var.enable_studio ? 1 : 0
  source                   = "../../modules/studio"
  name_prefix              = local.name_prefix
  vpc_id                   = module.network.vpc_id
  private_subnet_ids       = module.network.private_subnet_ids
  domain_security_group_id = try(module.security[0].domain_security_group_id, null)
  user_security_group_id   = try(module.security[0].user_security_group_id, null)
  execution_role_arn       = try(module.iam[0].execution_role_arn, null)
  kms_key_arn              = module.kms.key_arn
  user_profile_name        = var.user_profile_name
  jupyterlab_instance_type = var.jupyterlab_instance_type
  start_jupyterlab         = var.start_jupyterlab

  depends_on = [module.endpoints, module.security, module.iam]
}
