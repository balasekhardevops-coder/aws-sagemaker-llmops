data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  immutable_subject = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}"
  plan_subject      = "${local.immutable_subject}:ref:refs/heads/main"
  apply_subject     = "${local.immutable_subject}:environment:terraform-${var.environment}"
}

data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.plan_subject]
    }
  }
}

data "aws_iam_policy_document" "apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.apply_subject]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "${var.name_prefix}-terraform-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json
}
resource "aws_iam_role" "apply" {
  name               = "${var.name_prefix}-terraform-apply"
  assume_role_policy = data.aws_iam_policy_document.apply_trust.json
}
resource "aws_iam_role_policy_attachment" "plan" {
  for_each   = var.plan_policy_arns
  role       = aws_iam_role.plan.name
  policy_arn = each.value
}
resource "aws_iam_role_policy_attachment" "apply" {
  for_each   = var.apply_policy_arns
  role       = aws_iam_role.apply.name
  policy_arn = each.value
}
