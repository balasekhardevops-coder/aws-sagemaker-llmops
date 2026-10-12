variable "name_prefix" { type = string }
variable "aws_region" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "private_route_table_ids" { type = list(string) }
variable "endpoint_security_group_id" { type = string }

variable "enabled_interface_endpoints" {
  description = "Interface VPC endpoints to create. S3 Gateway is always created separately."
  type        = set(string)
  default     = ["api", "runtime"]

  validation {
    condition = length(setsubtract(
      var.enabled_interface_endpoints,
      toset(["api", "runtime", "studio", "sts", "logs"])
    )) == 0
    error_message = "Allowed values: api, runtime, studio, sts, logs."
  }
}
