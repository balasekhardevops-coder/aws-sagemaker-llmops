resource "aws_security_group" "studio" {
  name        = "${local.name_prefix}-studio"
  description = "Per-user SageMaker Studio traffic for the initial single developer"
  vpc_id      = aws_vpc.llmops.id
  tags        = { Name = "${local.name_prefix}-studio" }
}

resource "aws_security_group" "endpoints" {
  name        = "${local.name_prefix}-vpce"
  description = "Interface endpoint HTTPS access from SageMaker Studio only"
  vpc_id      = aws_vpc.llmops.id
  tags        = { Name = "${local.name_prefix}-vpce" }
}

resource "aws_vpc_security_group_ingress_rule" "studio_interapp" {
  security_group_id            = aws_security_group.studio.id
  referenced_security_group_id = aws_security_group.studio.id
  ip_protocol                  = "tcp"
  from_port                    = 8192
  to_port                      = 65535
  description                  = "Jupyter inter-app connections within one user profile"
}

resource "aws_vpc_security_group_egress_rule" "studio_interapp" {
  security_group_id            = aws_security_group.studio.id
  referenced_security_group_id = aws_security_group.studio.id
  ip_protocol                  = "tcp"
  from_port                    = 8192
  to_port                      = 65535
  description                  = "Jupyter inter-app return traffic"
}

resource "aws_vpc_security_group_ingress_rule" "studio_nfs" {
  security_group_id            = aws_security_group.studio.id
  referenced_security_group_id = aws_security_group.studio.id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  description                  = "Studio NFS where managed EFS shares the Studio group"
}

resource "aws_vpc_security_group_egress_rule" "studio_nfs" {
  security_group_id = aws_security_group.studio.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  description       = "NFS to SageMaker-managed EFS mount targets inside the VPC"
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_https" {
  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.studio.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Allow HTTPS from SageMaker Studio to interface endpoints"
}

resource "aws_vpc_security_group_egress_rule" "studio_https_endpoints" {
  security_group_id            = aws_security_group.studio.id
  referenced_security_group_id = aws_security_group.endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Allow HTTPS to VPC interface endpoint interfaces"
}

resource "aws_vpc_security_group_egress_rule" "studio_https_s3" {
  security_group_id = aws_security_group.studio.id
  prefix_list_id    = aws_vpc_endpoint.s3.prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "Allow HTTPS to S3 through the gateway endpoint prefix list"
}
