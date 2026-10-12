module "github_oidc" {
  source            = "../modules/github-oidc"
  name_prefix       = "sagemaker-llmops-${var.environment}"
  environment       = var.environment
  github_owner      = "balasekhardevops-coder"
  github_owner_id   = "277724570"
  github_repo       = "aws-sagemaker-llmops"
  github_repo_id    = "1415110746"
  plan_policy_arns  = var.plan_policy_arns
  apply_policy_arns = var.apply_policy_arns
}
