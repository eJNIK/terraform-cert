# Root Module Outputs
#
# These outputs expose information from both the VPC module and local resources.
# Notice how we reference module outputs using module.<name>.<output>

# ============================================
# VPC Module Outputs
# ============================================

output "vpc_id" {
  description = "The ID of the VPC (from module)"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC (from module)"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (from module)"
  value       = module.vpc.public_subnet_ids
}

output "public_subnet_azs" {
  description = "Availability zones of public subnets (from module)"
  value       = module.vpc.public_subnet_azs
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (from module)"
  value       = module.vpc.private_subnet_ids
}

output "private_subnet_azs" {
  description = "Availability zones of private subnets (from module)"
  value       = module.vpc.private_subnet_azs
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway (from module)"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (from module)"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "List of NAT Gateway public IPs (from module)"
  value       = module.vpc.nat_gateway_public_ips
}

# ============================================
# EC2 Instance Outputs
# ============================================

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "instance_availability_zone" {
  description = "The availability zone where the instance is deployed"
  value       = aws_instance.web_server.availability_zone
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.web_sg.id
}

output "web_server_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.web_server.public_ip}"
}

# ============================================
# Summary Output
# ============================================

output "deployment_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    vpc_id               = module.vpc.vpc_id
    vpc_cidr             = module.vpc.vpc_cidr
    public_subnet_count  = length(module.vpc.public_subnet_ids)
    private_subnet_count = length(module.vpc.private_subnet_ids)
    nat_gateways         = length(module.vpc.nat_gateway_ids)
    instance_id          = aws_instance.web_server.id
    web_url              = "http://${aws_instance.web_server.public_ip}"
  }
}
