"""Offline structural smoke checks; real Terraform validation requires terraform + AWS provider."""
from pathlib import Path
import subprocess
import unittest
import yaml

ROOT = Path(__file__).resolve().parents[1]
DEV = ROOT / 'terraform/environments/dev'
IDENTITY = ROOT / 'terraform/identity'

class RepoChecks(unittest.TestCase):
    def test_bash_syntax(self):
        for script in sorted((ROOT/'scripts').glob('*.sh')):
            with self.subTest(script=script.name):
                self.assertEqual(subprocess.run(['bash','-n',str(script)],capture_output=True).returncode,0)

    def test_yaml_parse(self):
        for file in sorted((ROOT/'.github/workflows').glob('*.yml')):
            with self.subTest(file=file.name):
                doc=yaml.safe_load(file.read_text())
                self.assertIn('jobs',doc)

    def test_dev_state_addresses_preserved(self):
        text='\n'.join(f.read_text() for f in DEV.glob('*.tf'))
        self.assertIn('resource "aws_vpc" "llmops"',text)
        self.assertIn('resource "aws_s3_bucket" "llmops_data"',text)
        self.assertIn('resource "aws_vpc_endpoint" "s3"',text)
        self.assertNotIn('module "network"',text)
        self.assertNotIn('module "data_bucket"',text)
        self.assertNotIn('module "endpoints"',text)
        self.assertNotIn('module "security"',text)
        self.assertNotIn('module "iam"',text)
        self.assertIn('module "studio"',text)

    def test_identity_roles_and_s3_permissions(self):
        oidc=(ROOT/'terraform/modules/github-oidc/main.tf').read_text()
        policy=(IDENTITY/'policies.tf').read_text()
        self.assertIn('data "aws_iam_openid_connect_provider" "github"',oidc)
        self.assertNotIn('resource "aws_iam_openid_connect_provider" "github"',oidc)
        self.assertIn('environment:terraform-${var.environment}',oidc)
        self.assertIn('ref:refs/heads/main',oidc)
        for s in ['"s3:ListBucket"','"s3:GetObject"','"s3:PutObject"','"s3:DeleteObject"', '.tflock']:
            self.assertIn(s,policy)
        self.assertIn('resource "aws_iam_role_policy" "apply_infrastructure"', (IDENTITY/'main.tf').read_text())

    def test_workflow_consistency(self):
        workflow=(ROOT/'.github/workflows/terraform-reusable-deploy.yml').read_text()
        setup=(ROOT/'scripts/setup-github-env.sh').read_text()
        self.assertIn('state_key=\'dev/terraform.tfstate\'',workflow)
        self.assertIn('environment:',workflow)
        self.assertIn('terraform-${{ inputs.target_environment }}',workflow)
        self.assertIn('gh variable set "AWS_PLAN_ROLE_${SUFFIX}"',setup)
        self.assertIn('gh variable set "AWS_APPLY_ROLE_${SUFFIX}"',setup)
        self.assertIn('aws sts get-caller-identity',workflow)

    def test_no_sensitive_local_artifacts_in_archive_source(self):
        self.assertFalse((ROOT/'trust-policy.json').exists())
        self.assertFalse(list(ROOT.rglob('terraform.tfstate')))
        self.assertFalse(list(ROOT.rglob('*.tfplan')))
        self.assertFalse(list(ROOT.rglob('*.tfvars')))

if __name__=='__main__':
    unittest.main()
