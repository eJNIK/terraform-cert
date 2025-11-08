output "workspace" {
  description = "Current workspace name"
  value       = terraform.workspace
}

output "configuration" {
  description = "Full configuration for current workspace"
  value       = local.workspace_config
}

output "config_file" {
  description = "Path to generated config file"
  value       = local_file.config.filename
}

output "deployment_status" {
  description = "Deployment information"
  value = {
    workspace       = terraform.workspace
    deployment_name = local.deployment_name
    region          = local.workspace_config.deployment_region
    instances       = local.workspace_config.instance_count
    monitoring      = local.is_production ? "enabled" : "disabled"
  }
}
