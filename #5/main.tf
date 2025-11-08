resource "null_resource" "deployment" {
    provisioner "local-exec" {
        command = "echo Deploying ${local.deployment_name} to region ${local.workspace_config.deployment_region}"
    }
    triggers = {
        instance_count    = local.workspace_config.instance_count
        deployment_region = local.workspace_config.deployment_region
        backup_schedule   = local.workspace_config.backup_schedule
    }
}

resource "null_resource" "monitoring" {
  count = local.is_production ? 1 : 0

  triggers = {
    deployment_id = null_resource.deployment.id
  }

  provisioner "local-exec" {
    command = "echo Enabling monitoring for production environment"
  }
}
