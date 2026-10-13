output "aws_account_id" { value = data.aws_caller_identity.current.account_id }
output "aws_region" { value = var.aws_region }
output "vpc_id" { value = aws_vpc.llmops.id }
output "private_subnet_ids" { value = [for k in sort(keys(aws_subnet.private)) : aws_subnet.private[k].id] }
output "s3_data_bucket" { value = aws_s3_bucket.llmops_data.id }
output "sagemaker_domain_id" { value = module.studio.domain_id }
output "sagemaker_user_profile" { value = module.studio.user_profile_name }
output "jupyterlab_space_name" { value = module.studio.space_name }
output "interface_endpoint_ids" { value = { for name, ep in aws_vpc_endpoint.interface : name => ep.id } }
