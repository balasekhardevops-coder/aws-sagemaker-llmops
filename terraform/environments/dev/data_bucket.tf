resource "aws_s3_bucket" "llmops_data" {
  bucket        = "${local.name_prefix}-data-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  force_destroy = false
  tags          = { Name = "${local.name_prefix}-data" }
}

resource "aws_s3_bucket_versioning" "llmops_data" {
  bucket = aws_s3_bucket.llmops_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "llmops_data" {
  bucket = aws_s3_bucket.llmops_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "llmops_data" {
  bucket                  = aws_s3_bucket.llmops_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "data_tls" {
  statement {
    sid     = "RequireTLS"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [aws_s3_bucket.llmops_data.arn, "${aws_s3_bucket.llmops_data.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "data_tls" {
  bucket     = aws_s3_bucket.llmops_data.id
  policy     = data.aws_iam_policy_document.data_tls.json
  depends_on = [aws_s3_bucket_public_access_block.llmops_data]
}
