resource "aws_sagemaker_domain" "this" {
  domain_name = "${var.name_prefix}-domain"
  auth_mode   = "IAM"
  app_network_access_type       = "VpcOnly"
  app_security_group_management = "Customer"
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids
  kms_key_id = var.kms_key_arn

  default_user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [var.user_security_group_id]
    jupyter_lab_app_settings {
      default_resource_spec { instance_type = var.jupyterlab_instance_type }
      app_lifecycle_management {
        idle_settings {
          lifecycle_management    = "ENABLED"
          idle_timeout_in_minutes = 60
        }
      }
    }
  }
  default_space_settings {
    execution_role  = var.execution_role_arn
    security_groups = [var.user_security_group_id]
    jupyter_lab_app_settings {
      default_resource_spec { instance_type = var.jupyterlab_instance_type }
    }
  }
  domain_settings {
    security_group_ids = [var.domain_security_group_id]
  }
  retention_policy { home_efs_file_system = "Retain" }
  tags = { Name = "${var.name_prefix}-domain" }
}
resource "aws_sagemaker_user_profile" "developer" {
  domain_id         = aws_sagemaker_domain.this.id
  user_profile_name = var.user_profile_name
  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [var.user_security_group_id]
  }
}
resource "aws_sagemaker_space" "jupyterlab" {
  domain_id          = aws_sagemaker_domain.this.id
  space_name         = "llmops-jupyterlab"
  space_display_name = "LLMOps JupyterLab"
  ownership_settings {
    owner_user_profile_name = aws_sagemaker_user_profile.developer.user_profile_name
  }
  space_sharing_settings { sharing_type = "Private" }
  space_settings {
    app_type = "JupyterLab"
    jupyter_lab_app_settings {
      default_resource_spec { instance_type = var.jupyterlab_instance_type }
    }
    space_storage_settings {
      ebs_storage_settings { ebs_volume_size_in_gb = 20 }
    }
  }
}
resource "aws_sagemaker_app" "jupyterlab" {
  count = var.start_jupyterlab ? 1 : 0
  domain_id  = aws_sagemaker_domain.this.id
  space_name = aws_sagemaker_space.jupyterlab.space_name
  app_type   = "JupyterLab"
  app_name   = "default"
  resource_spec { instance_type = var.jupyterlab_instance_type }
}
