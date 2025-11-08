# Lab 02: Terraform Modules
# Exam Objectives:
# - Understand and use modules
# - Module inputs and outputs
# - Module composition
# - Source code organization
# - Code reusability

# Configure Terraform settings and required providers
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
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
      Lab         = "lab-02-modules"
    }
  }
}

# ============================================
# VPC Module Usage
# ============================================


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.owner_tag}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# ============================================
# Data Sources
# ============================================

# Get latest Amazon Linux 2023 AMI
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
# Security Group
# ============================================

resource "aws_security_group" "web_sg" {
  name        = "${var.owner_tag}-web-server-sg"
  description = "Security group for web server"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
# EC2 Instance in Public Subnet
# ============================================

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # Deploy to first public subnet created by module
  subnet_id = module.vpc.public_subnets[0]

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              cat > /var/www/html/index.html <<'HTML'
              <html>
              <head><title>Terraform Modules Lab</title></head>
              <body>
                <h1>Hello from Terraform Lab 02!</h1>
                <h2>Using Terraform Modules</h2>
                <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
                <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
                <p><strong>VPC Module:</strong> Successfully deployed!</p>
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
    Name = "${var.owner_tag}-web-server"
  }
}


module "bastion" {
  source           = "./modules/bastion"
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnets[0]
  ami_id           = data.aws_ami.amazon_linux_2023.id
}


# ============================================
# DB Subnet
# ============================================

module "db_subnet" {
  source             = "./modules/db_subnet"
  private_subnet_ids = module.vpc.database_subnets
}
