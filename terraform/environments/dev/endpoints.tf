locals {
  # Endpoint set required for private Studio, SDK credentials, training status, and inference.
  interface_endpoint_services = {
    api     = "com.amazonaws.${var.aws_region}.sagemaker.api"
    runtime = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
    studio  = "aws.sagemaker.${var.aws_region}.studio"
    sts     = "com.amazonaws.${var.aws_region}.sts"
    logs    = "com.amazonaws.${var.aws_region}.logs"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.llmops.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids   = values(aws_route_table.private)[*].id
  tags              = { Name = "${local.name_prefix}-s3-gateway" }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = { for name, service in local.interface_endpoint_services : name => service if contains(var.enabled_interface_endpoints, name) }

  vpc_id              = aws_vpc.llmops.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  tags                = { Name = "${local.name_prefix}-${each.key}-endpoint" }
}
