data "aws_caller_identity" "current" {}
data "aws_iam_policy_document" "key" {
  statement {
    sid       = "EnableAccountIAMPolicies"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}
resource "aws_kms_key" "this" {
  description             = "${var.name_prefix} SageMaker and S3 storage encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.key.json
}
resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-data"
  target_key_id = aws_kms_key.this.key_id
}
