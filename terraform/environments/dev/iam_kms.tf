# Studio EFS KMS permissions: key usage is constrained to this project's key.
data "aws_iam_policy_document" "studio_kms" {
  statement {
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [module.kms.key_arn]
  }
  statement {
    actions   = ["kms:CreateGrant"]
    resources = [module.kms.key_arn]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}
resource "aws_iam_role_policy" "studio_kms" {
  name   = "${local.name_prefix}-studio-kms"
  role   = aws_iam_role.studio_execution.id
  policy = data.aws_iam_policy_document.studio_kms.json
}
