locals {
  # Only create interface endpoints explicitly selected by the environment.
  interface_services = {
    api     = "com.amazonaws.${var.aws_region}.sagemaker.api"
    runtime = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
    studio  = "aws.sagemaker.${var.aws_region}.studio"
    sts     = "com.amazonaws.${var.aws_region}.sts"
    logs    = "com.amazonaws.${var.aws_region}.logs"
  }

  selected_interface_services = {
    for name, service in local.interface_services : name => service
    if contains(var.enabled_interface_endpoints, name)
  }
}

# S3 Gateway endpoint is independent of the interface endpoint selection.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = { Name = "${var.name_prefix}-s3-gateway" }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.selected_interface_services

  vpc_id              = var.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.endpoint_security_group_id]
  private_dns_enabled = true

  tags = { Name = "${var.name_prefix}-${each.key}-vpce" }
}
