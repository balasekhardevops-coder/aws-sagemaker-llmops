locals {
  state_path_prefix = var.environment == "dev" ? "dev/" : "${var.environment}/"
  state_bucket_arn  = "arn:aws:s3:::${var.state_bucket}"
  # ARN wildcard matches the region-specific state keys for QA / Prod.
  # Dev Mumbai retains the existing flat key; other Dev regions use nested keys.
  state_object_arns  = var.environment == "dev" ? ["${local.state_bucket_arn}/dev/terraform.tfstate", "${local.state_bucket_arn}/dev/*/terraform.tfstate"] : ["${local.state_bucket_arn}/${var.environment}/*/terraform.tfstate"]
  state_lock_arns    = [for arn in local.state_object_arns : "${arn}.tflock"]
  project_prefix     = "sagemaker-llmops-${var.environment}"
  project_bucket_arn = "arn:aws:s3:::${local.project_prefix}*"
  project_object_arn = "arn:aws:s3:::${local.project_prefix}*/*"
  project_role_arn   = "arn:aws:iam::${var.expected_account_id}:role/${local.project_prefix}*"
}

data "aws_iam_policy_document" "backend" {
  statement {
    sid       = "ListOnlyEnvironmentState"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.state_path_prefix}*", local.state_path_prefix]
    }
  }
  statement {
    sid       = "StateBucketLocation"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.state_bucket_arn]
  }
  statement {
    sid       = "ReadAndWriteState"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = local.state_object_arns
  }
  statement {
    sid       = "NativeS3LockFile"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = local.state_lock_arns
  }
}

# Terraform apply gets an explicit infrastructure write action allowlist rather
# than AdministratorAccess or PowerUserAccess. This is a LAB baseline; EC2/KMS
# create actions with Resource '*' require additional account isolation / SCPs
# for production and must be narrowed further to your organisation's standards.
data "aws_iam_policy_document" "apply_infrastructure" {
  statement {
    sid = "ManageProjectNetworking"
    actions = [
      "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:ModifyVpcAttribute", "ec2:CreateTags", "ec2:DeleteTags",
      "ec2:CreateSubnet", "ec2:DeleteSubnet", "ec2:ModifySubnetAttribute",
      "ec2:CreateRouteTable", "ec2:DeleteRouteTable", "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
      "ec2:CreateVpcEndpoint", "ec2:ModifyVpcEndpoint", "ec2:DeleteVpcEndpoints",
      "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup", "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress", "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
      "ec2:ModifySecurityGroupRules", "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress"
    ]
    resources = ["*"]
  }
  statement {
    sid = "ManageProjectDataBucket"
    actions = [
      "s3:CreateBucket", "s3:DeleteBucket", "s3:PutBucketTagging", "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration", "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketPolicy", "s3:DeleteBucketPolicy", "s3:PutBucketOwnershipControls",
      "s3:PutBucketAcl", "s3:GetBucketAcl", "s3:PutBucketLogging"
    ]
    resources = [local.project_bucket_arn]
  }
  statement {
    sid       = "ManageProjectDataObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [local.project_object_arn]
  }
  statement {
    sid = "ManageProjectStudioExecutionRole"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:UpdateAssumeRolePolicy", "iam:PutRolePolicy",
      "iam:DeleteRolePolicy", "iam:TagRole", "iam:UntagRole", "iam:UpdateRoleDescription"
    ]
    resources = [local.project_role_arn]
  }
  statement {
    sid       = "PassOnlyProjectSageMakerRole"
    actions   = ["iam:PassRole"]
    resources = [local.project_role_arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["sagemaker.amazonaws.com"]
    }
  }
  statement {
    sid = "ManageProjectKMS"
    actions = [
      "kms:CreateKey", "kms:TagResource", "kms:UntagResource", "kms:EnableKeyRotation",
      "kms:DisableKeyRotation", "kms:CreateAlias", "kms:UpdateAlias", "kms:DeleteAlias",
      "kms:PutKeyPolicy", "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion",
      "kms:CreateGrant", "kms:Decrypt", "kms:DescribeKey", "kms:GenerateDataKeyWithoutPlainText",
      "kms:ListResourceTags", "kms:GetKeyPolicy"
    ]
    resources = ["*"]
  }
  statement {
    sid       = "CreateSageMakerServiceLinkedRole"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["sagemaker.amazonaws.com"]
    }
  }
  statement {
    sid = "ManageProjectSageMakerStudio"
    actions = [
      "sagemaker:CreateDomain", "sagemaker:UpdateDomain", "sagemaker:DeleteDomain",
      "sagemaker:CreateUserProfile", "sagemaker:UpdateUserProfile", "sagemaker:DeleteUserProfile",
      "sagemaker:CreateSpace", "sagemaker:UpdateSpace", "sagemaker:DeleteSpace",
      "sagemaker:CreateApp", "sagemaker:DeleteApp", "sagemaker:AddTags", "sagemaker:DeleteTags"
    ]
    resources = ["*"]
  }
  statement {
    sid = "AllowSageMakerManagedEFS"
    actions = [
      "elasticfilesystem:CreateFileSystem", "elasticfilesystem:DeleteFileSystem",
      "elasticfilesystem:CreateMountTarget", "elasticfilesystem:DeleteMountTarget",
      "elasticfilesystem:DescribeFileSystems", "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:CreateTags", "elasticfilesystem:DeleteTags",
      "elasticfilesystem:TagResource", "elasticfilesystem:UntagResource"
    ]
    resources = ["*"]
  }
}
