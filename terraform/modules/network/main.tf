data "aws_availability_zones" "available" { state = "available" }

locals {
  subnets = {
    for i, cidr in var.private_subnet_cidrs : tostring(i) => {
      cidr = cidr
      az   = data.aws_availability_zones.available.names[i]
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_subnet" "private" {
  for_each                = local.subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false
  tags = { Name = "${var.name_prefix}-private-${each.key}" }
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this.id
  # Intentionally no 0.0.0.0/0 route, NAT gateway, or internet gateway.
  tags = { Name = "${var.name_prefix}-private-rt-${each.key}" }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
