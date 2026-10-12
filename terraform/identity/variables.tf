variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "expected_account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.expected_account_id))
    error_message = "Must be a 12-digit AWS account ID."
  }
}
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Choose dev, qa or prod."
  }
}
variable "state_bucket" {
  description = "Existing S3 Terraform state bucket; one per account/region."
  type        = string
}
variable "plan_policy_arns" {
  description = "Optional additional enterprise IAM policies for the plan role."
  type        = set(string)
  default     = []
}
variable "apply_policy_arns" {
  description = "Optional additional enterprise IAM policies for the apply role."
  type        = set(string)
  default     = []
}
