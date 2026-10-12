data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "AllowSageMakerService"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "studio" {
  name = "${var.name_prefix}-studio-execution"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}
data "aws_iam_policy_document" "studio" {
  statement {
    sid = "ProjectBucketMetadata"
    actions = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [var.data_bucket_arn]
  }
  statement {
    sid = "ProjectDataReadWrite"
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = ["${var.data_bucket_arn}/*"]
  }
  statement {
    sid = "UseProjectEncryptionKey"
    actions = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey", "kms:CreateGrant"]
    resources = [var.kms_key_arn]
  }
  statement {
    sid = "ExploreSageMakerJobs"
    actions = ["sagemaker:ListTrainingJobs", "sagemaker:DescribeTrainingJob", "sagemaker:ListEndpoints", "sagemaker:DescribeEndpoint"]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy" "studio" {
  name = "${var.name_prefix}-studio-access"
  role = aws_iam_role.studio.id
  policy = data.aws_iam_policy_document.studio.json
}
