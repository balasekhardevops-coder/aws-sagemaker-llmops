output "aws_account_id" { value = data.aws_caller_identity.current.account_id }
output "vpc_id" { value = module.network.vpc_id }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
output "s3_data_bucket" { value = module.data_bucket.bucket_id }
output "sagemaker_domain_id" { value = module.studio.domain_id }
output "sagemaker_user_profile" { value = module.studio.user_profile_name }
output "jupyterlab_space_name" { value = module.studio.space_name }
output "interface_endpoint_ids" { value = module.endpoints.interface_endpoint_ids }

output "interface_vpc_endpoint_ids" {
  description = "Interface VPC endpoints provisioned in this environment"
  value       = module.endpoints.interface_endpoint_ids
}
