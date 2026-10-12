variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "expected_account_id" { type = string }
variable "environment" { type = string }
variable "plan_policy_arns" { type = set(string) }
variable "apply_policy_arns" { type = set(string) }
