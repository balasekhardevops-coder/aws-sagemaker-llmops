# Separate SG for the domain and the single user; do not self-reference a
# shared domain SG across all user profiles in a multi-user deployment.
resource "aws_security_group" "domain" {
  name        = "${var.name_prefix}-studio-domain"
  description = "Studio domain and SageMaker-managed EFS traffic"
  vpc_id      = var.vpc_id
  tags = { Name = "${var.name_prefix}-studio-domain" }
}

resource "aws_security_group" "user" {
  name        = "${var.name_prefix}-studio-user"
  description = "Private JupyterLab communication for one developer"
  vpc_id      = var.vpc_id
  tags = { Name = "${var.name_prefix}-studio-user" }
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name_prefix}-vpce"
  description = "HTTPS access to private interface endpoints"
  vpc_id      = var.vpc_id
  tags = { Name = "${var.name_prefix}-vpce" }
}

resource "aws_vpc_security_group_ingress_rule" "user_interapp" {
  security_group_id            = aws_security_group.user.id
  referenced_security_group_id = aws_security_group.user.id
  from_port = 8192
  to_port   = 65535
  ip_protocol = "tcp"
  description = "Same-profile Jupyter app communication"
}
resource "aws_vpc_security_group_egress_rule" "user_interapp" {
  security_group_id            = aws_security_group.user.id
  referenced_security_group_id = aws_security_group.user.id
  from_port = 8192
  to_port   = 65535
  ip_protocol = "tcp"
  description = "Same-profile Jupyter app communication"
}

# NFS path to SageMaker-managed EFS mount targets.
resource "aws_vpc_security_group_ingress_rule" "domain_nfs_user" {
  security_group_id            = aws_security_group.domain.id
  referenced_security_group_id = aws_security_group.user.id
  from_port = 2049
  to_port = 2049
  ip_protocol = "tcp"
  description = "NFS from private Studio user"
}
resource "aws_vpc_security_group_ingress_rule" "domain_nfs_self" {
  security_group_id            = aws_security_group.domain.id
  referenced_security_group_id = aws_security_group.domain.id
  from_port = 2049
  to_port = 2049
  ip_protocol = "tcp"
  description = "NFS from domain-attached interfaces"
}
resource "aws_vpc_security_group_egress_rule" "user_nfs" {
  security_group_id = aws_security_group.user.id
  referenced_security_group_id = aws_security_group.domain.id
  from_port = 2049
  to_port = 2049
  ip_protocol = "tcp"
  description = "NFS to domain file system"
}
resource "aws_vpc_security_group_egress_rule" "domain_nfs" {
  security_group_id = aws_security_group.domain.id
  cidr_ipv4 = var.vpc_cidr
  from_port = 2049
  to_port = 2049
  ip_protocol = "tcp"
  description = "NFS within the VPC"
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_https_user" {
  security_group_id = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.user.id
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  description = "HTTPS from JupyterLab"
}
resource "aws_vpc_security_group_ingress_rule" "endpoint_https_domain" {
  security_group_id = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.domain.id
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  description = "HTTPS from domain components"
}
resource "aws_vpc_security_group_egress_rule" "user_https_endpoint" {
  security_group_id = aws_security_group.user.id
  referenced_security_group_id = aws_security_group.endpoints.id
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  description = "Private endpoints"
}
resource "aws_vpc_security_group_egress_rule" "domain_https_endpoint" {
  security_group_id = aws_security_group.domain.id
  referenced_security_group_id = aws_security_group.endpoints.id
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  description = "Private endpoints"
}

# S3 gateway endpoint traffic uses the AWS-managed S3 prefix list, not an SG.
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}
resource "aws_vpc_security_group_egress_rule" "user_https_s3" {
  security_group_id = aws_security_group.user.id
  prefix_list_id = data.aws_prefix_list.s3.id
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  description = "HTTPS through S3 gateway endpoint"
}
resource "aws_vpc_security_group_egress_rule" "domain_https_s3" {
  security_group_id = aws_security_group.domain.id
  prefix_list_id = data.aws_prefix_list.s3.id
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  description = "HTTPS through S3 gateway endpoint"
}

# Inter-application connections between the domain-level app SG and this user's SG.
# SageMaker documents TCP 8192-65535 for these app-to-app connections.
resource "aws_vpc_security_group_ingress_rule" "user_from_domain" {
  security_group_id            = aws_security_group.user.id
  referenced_security_group_id = aws_security_group.domain.id
  from_port                    = 8192
  to_port                      = 65535
  ip_protocol                  = "tcp"
  description                  = "Domain apps to user apps"
}
resource "aws_vpc_security_group_egress_rule" "domain_to_user" {
  security_group_id            = aws_security_group.domain.id
  referenced_security_group_id = aws_security_group.user.id
  from_port                    = 8192
  to_port                      = 65535
  ip_protocol                  = "tcp"
  description                  = "Domain apps to user apps"
}
resource "aws_vpc_security_group_ingress_rule" "domain_from_user" {
  security_group_id            = aws_security_group.domain.id
  referenced_security_group_id = aws_security_group.user.id
  from_port                    = 8192
  to_port                      = 65535
  ip_protocol                  = "tcp"
  description                  = "User apps to domain apps"
}
resource "aws_vpc_security_group_egress_rule" "user_to_domain" {
  security_group_id            = aws_security_group.user.id
  referenced_security_group_id = aws_security_group.domain.id
  from_port                    = 8192
  to_port                      = 65535
  ip_protocol                  = "tcp"
  description                  = "User apps to domain apps"
}
