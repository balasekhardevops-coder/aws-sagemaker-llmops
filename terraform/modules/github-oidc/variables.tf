variable "name_prefix" { type = string }
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa or prod."
  }
}
variable "github_owner" { type = string }
variable "github_owner_id" { type = string }
variable "github_repo" { type = string }
variable "github_repo_id" { type = string }
variable "plan_policy_arns" {
  description = "Existing IAM policy ARNs for planning, state lock, read-only cloud discovery. Must be separately provisioned."
  type        = set(string)
  default     = []
}
variable "apply_policy_arns" {
  description = "Existing scoped IAM policy ARNs allowing managed infrastructure changes plus backend access."
  type        = set(string)
  default     = []
}
