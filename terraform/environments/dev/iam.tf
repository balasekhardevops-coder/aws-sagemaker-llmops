data "aws_iam_policy_document" "sagemaker_trust" {
  statement {
    sid     = "SageMakerServiceAssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "studio_execution" {
  name               = "${local.name_prefix}-studio-execution"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_trust.json
}

# Deliberately scoped to our project bucket; training/Glue need their own roles later.
data "aws_iam_policy_document" "studio_data" {
  statement {
    sid       = "ListProjectBucket"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.llmops_data.arn]
  }
  statement {
    sid       = "ReadWriteProjectObjects"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.llmops_data.arn}/*"]
  }
  statement {
    sid       = "DescribeOnlySageMaker"
    actions   = ["sagemaker:ListTrainingJobs", "sagemaker:DescribeTrainingJob", "sagemaker:ListEndpoints", "sagemaker:DescribeEndpoint"]
    resources = ["*"]
  }
    statement {
    sid = "StudioApplicationDiscovery"

    actions = [
      "sagemaker:ListSpaces",
      "sagemaker:ListApps",
      "sagemaker:DescribeApp",
      "sagemaker:DescribeSpace",
      "sagemaker:ListUserProfiles",
      "sagemaker:DescribeUserProfile"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "studio_data" {
  name   = "${local.name_prefix}-studio-data"
  role   = aws_iam_role.studio_execution.id
  policy = data.aws_iam_policy_document.studio_data.json
}
