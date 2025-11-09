# Lab 05: Data Sources, Import, and For_Each
# Exam Objectives:
# - Use data sources to query existing resources
# - Import existing infrastructure into Terraform state
# - Understand for_each vs count
# - Use depends_on for explicit dependencies

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
      Environment = var.environment
      ManagedBy   = "Terraform"
      Lab         = "lab-05-data-import"
    }
  }
}

# ============================================
# Data Sources - Query Existing AWS Resources
# ============================================

# Get AWS account information
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}

# Get all available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get default VPC (if exists)
data "aws_vpc" "default" {
  default = true
}

# Get AMI with specific filters
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

# Get Ubuntu AMI for comparison
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================
# Resources using for_each (with map)
# ============================================

locals {
  # Map for S3 buckets - key is bucket purpose
  buckets = {
    logs = {
      purpose = "Application Logs"
      versioning = true
    }
    data = {
      purpose = "Data Storage"
      versioning = false
    }
    backups = {
      purpose = "Backup Storage"
      versioning = true
    }
  }

  # Map for security groups
  security_groups = {
    web = {
      description = "Web servers"
      ingress_ports = [80, 443]
    }
    app = {
      description = "Application servers"
      ingress_ports = [8080, 8443]
    }
    db = {
      description = "Database servers"
      ingress_ports = [3306, 5432]
    }
  }
}

# S3 buckets using for_each with map
resource "aws_s3_bucket" "example" {
  for_each = local.buckets

  bucket = "${var.owner_tag}-${each.key}-${data.aws_region.current.name}"

  tags = {
    Name    = "${var.owner_tag}-${each.key}-bucket"
    Purpose = each.value.purpose
  }
}

# S3 bucket versioning (for_each over buckets that need it)
resource "aws_s3_bucket_versioning" "example" {
  for_each = { for k, v in local.buckets : k => v if v.versioning }

  bucket = aws_s3_bucket.example[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

# ============================================
# VPC for Security Groups
# ============================================

resource "aws_vpc" "main" {
  cidr_block           = "10.5.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.owner_tag}-lab05-vpc"
  }
}

# Security groups using for_each
resource "aws_security_group" "example" {
  for_each = local.security_groups

  name        = "${var.owner_tag}-${each.key}-sg"
  description = each.value.description
  vpc_id      = aws_vpc.main.id

  # Dynamic ingress rules for each port
  dynamic "ingress" {
    for_each = each.value.ingress_ports

    content {
      description = "Port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.owner_tag}-${each.key}-sg"
    Type = each.key
  }
}

# ============================================
# Resources using count (with list)
# ============================================

# IAM users using count
resource "aws_iam_user" "example" {
  count = length(var.user_names)

  name = "${var.owner_tag}-${var.user_names[count.index]}"

  tags = {
    Name  = var.user_names[count.index]
    Index = count.index
  }
}

# ============================================
# Explicit Dependencies
# ============================================

# This resource explicitly depends on S3 buckets being created
resource "aws_s3_bucket_public_access_block" "example" {
  for_each = aws_s3_bucket.example

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Explicit dependency (though implicit exists through each.value.id)
  depends_on = [aws_s3_bucket.example]
}

# ============================================
# Resources for Import Practice
# ============================================

# This will be manually created and then imported
# Uncomment after manual creation
# resource "aws_s3_bucket" "imported" {
#   bucket = "${var.owner_tag}-imported-bucket-${data.aws_region.current.name}"
#
#   tags = {
#     Name      = "${var.owner_tag}-imported-bucket"
#     Imported  = "true"
#     CreatedBy = "Manual-Then-Imported"
#   }
# }
