# Output Values for Lab 01
#
# Outputs allow you to extract and display information about your infrastructure.
# They're useful for:
# - Displaying important information after terraform apply
# - Passing data between Terraform configurations
# - Referencing values in scripts or other tools

# ============================================
# VPC Outputs
# ============================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
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

output "instance_state" {
  description = "The state of the EC2 instance"
  value       = aws_instance.web_server.instance_state
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.web_sg.id
}

output "security_group_name" {
  description = "The name of the security group"
  value       = aws_security_group.web_sg.name
}

output "ami_id" {
  description = "The AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "web_server_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "az" {
  description = "Availability Zone of the EC2 instance"
  value = aws_instance.web_server.availability_zone
}

output "instance_private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}

output "arn" {
  description = "ARN of the EC2 instance"
  value = aws_instance.web_server.arn
}

# Formatted output for easy SSH access
output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_instance.web_server.public_ip}"
}
