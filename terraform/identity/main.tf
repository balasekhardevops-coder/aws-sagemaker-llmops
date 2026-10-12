module "github_oidc" {
  source            = "../modules/github-oidc"
  name_prefix       = "sagemaker-llmops-${var.environment}"
  environment       = var.environment
  github_owner      = "balasekhardevops-coder"
  github_owner_id   = "277724570"
  github_repo       = "aws-sagemaker-llmops"
  github_repo_id    = "1415110746"
  plan_policy_arns  = setunion(var.plan_policy_arns, toset(["arn:aws:iam::aws:policy/ReadOnlyAccess"]))
  apply_policy_arns = setunion(var.apply_policy_arns, toset(["arn:aws:iam::aws:policy/ReadOnlyAccess"]))
}

# Grant the roles backend permissions before attempting GitHub Actions. IAM
# policy is created here rather than requiring an out-of-band custom policy ARN.
resource "aws_iam_role_policy" "plan_state" {
  name   = "${var.environment}-terraform-backend"
  role   = module.github_oidc.plan_role_name
  policy = data.aws_iam_policy_document.backend.json
}
resource "aws_iam_role_policy" "apply_state" {
  name   = "${var.environment}-terraform-backend"
  role   = module.github_oidc.apply_role_name
  policy = data.aws_iam_policy_document.backend.json
}
resource "aws_iam_role_policy" "apply_infrastructure" {
  name   = "${var.environment}-terraform-managed-infrastructure"
  role   = module.github_oidc.apply_role_name
  policy = data.aws_iam_policy_document.apply_infrastructure.json
}
