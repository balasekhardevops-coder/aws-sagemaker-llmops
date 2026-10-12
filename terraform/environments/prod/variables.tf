variable "project_name" {
  type    = string
  default = "sagemaker-llmops"
}
variable "environment" {
  type    = string
  default = "prod"
  validation {
    condition     = var.environment == "prod"
    error_message = "This root module is only for prod."
  }
}
variable "aws_region" {
  type    = string
  default = "ap-south-1"
  validation {
    condition     = contains(["ap-south-1", "us-east-1", "eu-west-1"], var.aws_region)
    error_message = "Region must match one of the three approved workflow regions."
  }
}
variable "expected_account_id" {
  type        = string
  description = "Target AWS account ID, supplied by CI as TF_VAR_expected_account_id."
  validation {
    condition     = can(regex("^[0-9]{12}$", var.expected_account_id))
    error_message = "A 12-digit AWS account ID is required."
  }
}
variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.40.1.0/24", "10.40.2.0/24"]
}
variable "user_profile_name" {
  type    = string
  default = "llmops-developer"
}
variable "jupyterlab_instance_type" {
  type    = string
  default = "ml.m5.large"
}
variable "enable_studio" {
  type    = bool
  default = false
}
variable "start_jupyterlab" {
  type    = bool
  default = false
  validation {
    condition     = !var.start_jupyterlab || var.enable_studio
    error_message = "Cannot start JupyterLab when Studio is disabled."
  }
}
variable "enabled_interface_endpoints" {
  type    = set(string)
  default = ["api", "runtime"]
  validation {
    condition     = length(setsubtract(var.enabled_interface_endpoints, toset(["api", "runtime", "studio", "sts", "logs"]))) == 0
    error_message = "Unknown endpoint name."
  }
}
