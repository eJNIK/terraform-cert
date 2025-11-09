output "workspace_name" {
  description = "Current workspace name"
  value       = terraform.workspace
}

output "environment_config" {
  description = "Configuration for current environment"
  value       = local.env
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "instance_count" {
  description = "Number of instances deployed"
  value       = length(aws_instance.web)
}

output "instance_ids" {
  description = "List of instance IDs"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "List of instance public IPs"
  value       = aws_instance.web[*].public_ip
}

output "web_urls" {
  description = "URLs to access web servers"
  value       = [for ip in aws_instance.web[*].public_ip : "http://${ip}"]
}

output "deployment_summary" {
  description = "Summary of deployment"
  value = {
    workspace      = terraform.workspace
    instance_type  = local.env.instance_type
    instance_count = local.env.instance_count
    vpc_cidr       = local.env.vpc_cidr
    monitoring     = local.env.enable_monitoring
    web_urls       = [for ip in aws_instance.web[*].public_ip : "http://${ip}"]
  }
}
