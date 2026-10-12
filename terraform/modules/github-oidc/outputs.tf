output "plan_role_name" { value = aws_iam_role.plan.name }
output "apply_role_name" { value = aws_iam_role.apply.name }
output "plan_role_arn" { value = aws_iam_role.plan.arn }
output "apply_role_arn" { value = aws_iam_role.apply.arn }
output "oidc_provider_arn" { value = data.aws_iam_openid_connect_provider.github.arn }
