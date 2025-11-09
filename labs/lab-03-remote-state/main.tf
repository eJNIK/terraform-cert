# Lab 03: Remote State Management with S3 and DynamoDB
# Exam Objectives:
# - Understand backend configuration
# - Implement remote state storage
# - Configure state locking with DynamoDB
# - Migrate state from local to remote
# - Secure state files

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration - commented out initially
  # Uncomment after creating S3 bucket and DynamoDB table
  # backend "s3" {
  #   bucket         = "YOUR-BUCKET-NAME-HERE"
  #   key            = "lab-03/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner       = var.owner_tag
      Environment = var.environment
      ManagedBy   = "Terraform"
      Lab         = "lab-03-remote-state"
    }
  }
}

# ============================================
# S3 Bucket for Terraform State
# ============================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.owner_tag}-terraform-state-${var.aws_region}"

  tags = {
    Name        = "${var.owner_tag}-terraform-state"
    Description = "Terraform state storage"
  }
}

# Enable versioning for state file history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================
# DynamoDB Table for State Locking
# ============================================

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.owner_tag}-terraform-lock"
    Description = "Terraform state locking"
  }
}

# ============================================
# Example VPC (to demonstrate state management)
# ============================================

resource "aws_vpc" "example" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.owner_tag}-example-vpc"
  }
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.owner_tag}-example-subnet"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
