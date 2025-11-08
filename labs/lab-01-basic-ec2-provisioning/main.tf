# Lab 01: Basic EC2 Provisioning with Terraform
# Exam Objectives:
# - Understand Terraform basics and workflow
# - Configure providers
# - Create and manage resources (VPC, Subnet, EC2, Security Groups)
# - Use input variables and outputs
# - Understand resource dependencies

# Configure Terraform settings and required providers
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources
  default_tags {
    tags = {
      Owner       = var.owner_tag
      Environment = var.environment
      ManagedBy   = "Terraform"
      Lab         = "lab-01-basic-ec2"
    }
  }
}

# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source to get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================
# VPC and Networking Resources
# ============================================

# VPC - Virtual Private Cloud
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.owner_tag}-vpc"
  }
}

# Internet Gateway - Allows communication between VPC and the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.owner_tag}-igw"
  }
}

# Public Subnet - Where our EC2 instance will live
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.owner_tag}-public-subnet"
  }
}

# Route Table - Defines network traffic routing rules
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route all traffic (0.0.0.0/0) to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.owner_tag}-public-rt"
  }
}

# Route Table Association - Associates the route table with the subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================
# Security Group
# ============================================

# Security Group for EC2 instance
resource "aws_security_group" "web_sg" {
  name        = "${var.owner_tag}-web-server-sg"
  description = "Security group for web server allowing HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  # Inbound rule for SSH (port 22)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # Inbound rule for HTTP (port 80)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  # Inbound rule for HTTPS (port 443)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_https_cidr
  }

  # Outbound rule - allow all traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.owner_tag}-web-server-sg"
  }
}

# ============================================
# EC2 Instance
# ============================================

# EC2 Instance
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  # Associate the security group
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # User data script to install and start a simple web server
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform Lab 01!</h1>" > /var/www/html/index.html
              echo "<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
              EOF

  # Root block device configuration
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.owner_tag}-web-server"
    Description = "Web server instance created by Terraform"
  }
}
