locals {
  common_tags = {
    created_by = "DevOps Team"
    managed_by = "Terraform"
    timestamp  = formatdate("YYYY-MM-DDTHH:mm:ssZ", timestamp())
  }

  environment_tags = {
  for env, config in var.environments : env => merge(
    local.common_tags,
    {
      Environment     = env
      CostCenter      = config.cost_center
      Owner           = config.owner
      BackupRequired  = tostring(config.backup_required)
    }
  )
}

  bucket_names = {
  for env, config in var.environments :
    env => lower(replace("myapp-${env}-${config.region}-${local.common_tags.timestamp}", ":", "-"))
 }
}
