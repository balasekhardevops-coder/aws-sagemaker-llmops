data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  subnet_map = {
    for index, cidr in var.private_subnet_cidrs :
    tostring(index) => {
      cidr = cidr
      az   = data.aws_availability_zones.available.names[index]
    }
  }
}

resource "aws_vpc" "llmops" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_subnet" "private" {
  for_each = local.subnet_map

  vpc_id                  = aws_vpc.llmops.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = { Name = "${local.name_prefix}-private-${each.key}" }
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.llmops.id
  # No 0.0.0.0/0 route, Internet Gateway, or NAT Gateway.
  # AWS automatically installs the VPC-local route.
  tags = { Name = "${local.name_prefix}-private-rt-${each.key}" }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
