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
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "private_subnet_cidrs" {
  type = list(string)
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
