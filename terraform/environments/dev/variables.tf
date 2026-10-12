variable "project_name" {
  type    = string
  default = "sagemaker-llmops"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "aws_region" {
  type    = string
  default = "ap-south-1"
  validation {
    condition     = contains(["ap-south-1", "us-east-1", "eu-west-1"], var.aws_region)
    error_message = "Choose one of the three supported regions."
  }
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}
variable "user_profile_name" {
  type    = string
  default = "llmops-developer"
}
variable "jupyterlab_instance_type" {
  type    = string
  default = "ml.m5.large"
}
variable "start_jupyterlab" {
  type    = bool
  default = false
}

# Dev default: minimal interface endpoint footprint; S3 Gateway always enabled.
variable "enabled_interface_endpoints" {
  type        = set(string)
  description = "Interface endpoints enabled for this environment"
  default     = ["api", "runtime"]

  validation {
    condition     = length(setsubtract(var.enabled_interface_endpoints, toset(["api", "runtime", "studio", "sts", "logs"]))) == 0
    error_message = "Allowed values: api, runtime, studio, sts, logs."
  }
}

# Local use can omit; GitHub Actions always supplies a per-environment account ID.
variable "expected_account_id" {
  type    = string
  default = ""
  validation {
    condition     = var.expected_account_id == "" || can(regex("^[0-9]{12}$", var.expected_account_id))
    error_message = "Expected an empty string or a 12-digit account ID."
  }
}
