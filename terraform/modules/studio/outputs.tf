output "domain_id" { value = aws_sagemaker_domain.this.id }
output "domain_arn" { value = aws_sagemaker_domain.this.arn }
output "user_profile_name" { value = aws_sagemaker_user_profile.developer.user_profile_name }
output "space_name" { value = aws_sagemaker_space.jupyterlab.space_name }
