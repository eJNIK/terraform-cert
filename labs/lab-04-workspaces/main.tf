# Lab 04: Terraform Workspaces
# Exam Objectives:
# - Understand workspaces concept
# - Manage multiple environments with workspaces
# - Use workspace-specific variables
# - Understand workspace state isolation

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner       = var.owner_tag
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
      Lab         = "lab-04-workspaces"
      Workspace   = terraform.workspace
    }
  }
}

# ============================================
# Workspace-Aware Configuration
# ============================================

locals {
  # Environment-specific configuration
  workspace_config = {
    dev = {
      instance_type    = "t2.micro"
      instance_count   = 1
      vpc_cidr         = "10.0.0.0/16"
      enable_monitoring = false
    }
    staging = {
      instance_type    = "t2.small"
      instance_count   = 2
      vpc_cidr         = "10.1.0.0/16"
      enable_monitoring = true
    }
    prod = {
      instance_type    = "t2.medium"
      instance_count   = 3
      vpc_cidr         = "10.2.0.0/16"
      enable_monitoring = true
    }
    qa = {
      instance_type    = "t2.small"
      instance_count   = 2
      vpc_cidr         = "10.3.0.0/16"
      enable_monitoring = true
    }
  }

  # Get current workspace config or default to dev
  env = lookup(local.workspace_config, terraform.workspace, local.workspace_config.dev)

  # Naming convention with workspace
  name_prefix = "${var.owner_tag}-${terraform.workspace}"
}

# ============================================
# Data Sources
# ============================================

data "aws_availability_zones" "available" {
  state = "available"
}

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

# ============================================
# VPC Resources
# ============================================

resource "aws_vpc" "main" {
  cidr_block           = local.env.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(local.env.vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================
# Security Group
# ============================================

resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group for web servers in ${terraform.workspace}"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = contains(["dev", "staging"], terraform.workspace) ? [1] : []

    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-web-sg"
  }
}

# ============================================
# EC2 Instances (count based on workspace)
# ============================================

resource "aws_instance" "web" {
  count = local.env.instance_count

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = local.env.instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.web.id]

  monitoring = local.env.enable_monitoring

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              cat > /var/www/html/index.html <<'HTML'
              <html>
              <head><title>Workspace: ${terraform.workspace}</title></head>
              <body style="font-family: Arial; margin: 50px;">
                <h1>Terraform Workspace Lab</h1>
                <h2>Environment: ${terraform.workspace}</h2>
                <p><strong>Instance:</strong> ${count.index + 1} of ${local.env.instance_count}</p>
                <p><strong>Instance Type:</strong> ${local.env.instance_type}</p>
                <p><strong>VPC CIDR:</strong> ${local.env.vpc_cidr}</p>
                <p><strong>Monitoring:</strong> ${local.env.enable_monitoring}</p>
                <hr>
                <p><em>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</em></p>
              </body>
              </html>
              HTML
              EOF

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name  = "${local.name_prefix}-web-${count.index + 1}"
    Index = count.index + 1
  }
}
