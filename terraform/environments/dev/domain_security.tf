# Keep the legacy Studio security group as a single-user SG.
# Domain apps use a separate SG; this avoids reusing a self-referencing SG
# across every user of the SageMaker domain.
resource "aws_security_group" "studio_domain" {
  name        = "${local.name_prefix}-studio-domain"
  description = "SageMaker Studio domain applications and EFS"
  vpc_id      = aws_vpc.llmops.id
  tags        = { Name = "${local.name_prefix}-studio-domain" }
}

resource "aws_vpc_security_group_ingress_rule" "domain_interapp_from_user" {
  security_group_id            = aws_security_group.studio_domain.id
  referenced_security_group_id = aws_security_group.studio.id
  from_port                    = 8192
  to_port                      = 65535
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "domain_interapp_to_user" {
  security_group_id            = aws_security_group.studio_domain.id
  referenced_security_group_id = aws_security_group.studio.id
  from_port                    = 8192
  to_port                      = 65535
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "user_interapp_from_domain" {
  security_group_id            = aws_security_group.studio.id
  referenced_security_group_id = aws_security_group.studio_domain.id
  from_port                    = 8192
  to_port                      = 65535
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "user_interapp_to_domain" {
  security_group_id            = aws_security_group.studio.id
  referenced_security_group_id = aws_security_group.studio_domain.id
  from_port                    = 8192
  to_port                      = 65535
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "domain_nfs_user" {
  security_group_id            = aws_security_group.studio_domain.id
  referenced_security_group_id = aws_security_group.studio.id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "domain_nfs_self" {
  security_group_id            = aws_security_group.studio_domain.id
  referenced_security_group_id = aws_security_group.studio_domain.id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "domain_nfs" {
  security_group_id = aws_security_group.studio_domain.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "endpoint_https_domain" {
  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.studio_domain.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "domain_https_endpoints" {
  security_group_id            = aws_security_group.studio_domain.id
  referenced_security_group_id = aws_security_group.endpoints.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "domain_https_s3" {
  security_group_id = aws_security_group.studio_domain.id
  prefix_list_id    = aws_vpc_endpoint.s3.prefix_list_id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
