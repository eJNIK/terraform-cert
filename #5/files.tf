resource "local_file" "config" {
  filename = "${path.module}/config-${terraform.workspace}.json"
  content  = jsonencode({
    workspace         = terraform.workspace
    deployment_name   = local.deployment_name
    instance_count    = local.workspace_config.instance_count
    enable_monitoring = local.workspace_config.enable_monitoring
    backup_schedule   = local.workspace_config.backup_schedule
    deployment_region = local.workspace_config.deployment_region
    is_production     = local.is_production
    all_regions       = local.all_regions
  })
}
