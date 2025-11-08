locals {
  workspace_config = var.configuration[terraform.workspace]
  is_production    = terraform.workspace == "prod"
  deployment_name  = "deployment-${terraform.workspace}-${formatdate("YYYYMMDD", timestamp())}"
  all_regions = distinct([
    for env, config in var.configuration :
    config.deployment_region
  ])
}
