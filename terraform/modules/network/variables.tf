variable "name_prefix" { type = string }
variable "vpc_cidr" { type = string }
variable "private_subnet_cidrs" {
  type = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least two private subnets are required."
  }
}
