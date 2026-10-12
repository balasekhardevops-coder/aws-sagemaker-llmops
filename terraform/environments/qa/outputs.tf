output "aws_account_id" { value = data.aws_caller_identity.current.account_id }
output "aws_region" { value = var.aws_region }
output "vpc_id" { value = module.network.vpc_id }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
output "s3_data_bucket" { value = module.data_bucket.bucket_id }
output "interface_endpoint_ids" {
  value = length(module.endpoints) > 0 ? module.endpoints[0].interface_endpoint_ids : {}
}
output "sagemaker_domain_id" {
  value = length(module.studio) > 0 ? module.studio[0].domain_id : null
}
output "sagemaker_user_profile" {
  value = length(module.studio) > 0 ? module.studio[0].user_profile_name : null
}
output "jupyterlab_space_name" {
  value = length(module.studio) > 0 ? module.studio[0].space_name : null
}
