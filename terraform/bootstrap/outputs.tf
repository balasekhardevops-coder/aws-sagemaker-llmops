output "state_bucket_name" {
  description = "Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "aws_account_id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "Deployment region"
  value       = var.aws_region
}