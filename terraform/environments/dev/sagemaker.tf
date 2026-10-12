resource "aws_sagemaker_domain" "llmops" {
  domain_name                   = "${local.name_prefix}-domain"
  auth_mode                     = "IAM"
  app_network_access_type       = "VpcOnly"
  app_security_group_management = "Customer"
  vpc_id                        = aws_vpc.llmops.id
  subnet_ids                    = values(aws_subnet.private)[*].id

  default_user_settings {
    execution_role  = aws_iam_role.studio_execution.arn
    security_groups = [aws_security_group.studio.id]
    jupyter_lab_app_settings {
      default_resource_spec {
        instance_type = var.jupyterlab_instance_type
      }
      app_lifecycle_management {
        idle_settings {
          lifecycle_management    = "ENABLED"
          idle_timeout_in_minutes = 60
        }
      }
    }
  }

  default_space_settings {
    execution_role  = aws_iam_role.studio_execution.arn
    security_groups = [aws_security_group.studio.id]
    jupyter_lab_app_settings {
      default_resource_spec {
        instance_type = var.jupyterlab_instance_type
      }
    }
  }

  domain_settings {
    security_group_ids = [aws_security_group.studio.id]
  }

  retention_policy {
    home_efs_file_system = "Retain"
  }

  tags = { Name = "${local.name_prefix}-domain" }

  depends_on = [
    aws_iam_role_policy.studio_data,
    aws_vpc_endpoint.s3,
    aws_vpc_endpoint.interface,
    aws_vpc_security_group_ingress_rule.studio_interapp,
    aws_vpc_security_group_egress_rule.studio_interapp,
    aws_vpc_security_group_egress_rule.studio_nfs,
    aws_vpc_security_group_egress_rule.studio_https_endpoints,
    aws_vpc_security_group_egress_rule.studio_https_s3,
    aws_vpc_security_group_ingress_rule.endpoints_https
  ]
}

resource "aws_sagemaker_user_profile" "developer" {
  domain_id         = aws_sagemaker_domain.llmops.id
  user_profile_name = "llmops-developer"
  user_settings {
    execution_role  = aws_iam_role.studio_execution.arn
    security_groups = [aws_security_group.studio.id]
  }
}

resource "aws_sagemaker_space" "jupyterlab" {
  domain_id          = aws_sagemaker_domain.llmops.id
  space_name         = "llmops-jupyterlab"
  space_display_name = "LLMOps JupyterLab"
  ownership_settings {
    owner_user_profile_name = aws_sagemaker_user_profile.developer.user_profile_name
  }
  space_sharing_settings {
    sharing_type = "Private"
  }
  space_settings {
    app_type = "JupyterLab"
    jupyter_lab_app_settings {
      default_resource_spec {
        instance_type = var.jupyterlab_instance_type
      }
    }
    space_storage_settings {
      ebs_storage_settings {
        ebs_volume_size_in_gb = 20
      }
    }
  }
}

# Start only with -var=start_jupyterlab=true; otherwise just storage persists.
resource "aws_sagemaker_app" "jupyterlab" {
  count      = var.start_jupyterlab ? 1 : 0
  domain_id  = aws_sagemaker_domain.llmops.id
  space_name = aws_sagemaker_space.jupyterlab.space_name
  app_name   = "default"
  app_type   = "JupyterLab"
  resource_spec {
    instance_type = var.jupyterlab_instance_type
  }
}
