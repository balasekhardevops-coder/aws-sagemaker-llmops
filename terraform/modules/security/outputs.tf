output "domain_security_group_id" { value = aws_security_group.domain.id }
output "user_security_group_id" { value = aws_security_group.user.id }
output "endpoint_security_group_id" { value = aws_security_group.endpoints.id }
