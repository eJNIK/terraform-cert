# Lab 06: Terraform Functions & Expressions
# Exam Objectives:
# - Understand and use built-in functions
# - String manipulation functions
# - Collection functions
# - Conditional expressions
# - For expressions
# - Splat expressions

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
      Lab         = "lab-06-functions"
      # Timestamp function
      CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
    }
  }
}

# ============================================
# Locals demonstrating various functions
# ============================================

locals {
  # String functions
  bucket_prefix = lower("${var.owner_tag}-${var.environment}")
  formatted_name = format("%s-%s-%03d", var.owner_tag, var.environment, 1)

  # Join lists into strings
  allowed_cidrs_string = join(", ", var.allowed_cidrs)

  # Split strings into lists
  availability_zones = split(",", "us-east-1a,us-east-1b,us-east-1c")

  # Replace in strings
  sanitized_owner = replace(var.owner_tag, ".", "-")

  # Regex operations
  is_prod = can(regex("prod", var.environment))

  # Collection functions
  all_ports = concat([80, 443], var.additional_ports)
  unique_ports = distinct(local.all_ports)
  port_count = length(local.unique_ports)
  first_port = element(local.unique_ports, 0)

  # Merge maps
  base_tags = {
    ManagedBy = "Terraform"
    Lab       = "lab-06"
  }

  custom_tags = merge(local.base_tags, var.extra_tags)

  # Conditional expressions
  instance_type = var.environment == "prod" ? "t2.medium" : "t2.micro"
  instance_count = var.environment == "prod" ? 3 : var.environment == "staging" ? 2 : 1

  # For expression - transform list to map
  az_map = {
    for idx, az in local.availability_zones :
    az => {
      index = idx
      subnet_cidr = cidrsubnet(var.vpc_cidr, 8, idx)
    }
  }

  # For expression - filter
  prod_envs = [for env in ["dev", "staging", "prod", "qa"] : env if can(regex("prod|staging", env))]

  # For expression - transform values
  uppercase_envs = [for env in local.prod_envs : upper(env)]

  # Flatten nested lists
  all_security_rules = flatten([
    for sg_name, sg in var.security_groups : [
      for port in sg.ports : {
        sg_name = sg_name
        port    = port
        protocol = sg.protocol
      }
    ]
  ])

  # Type conversions
  port_strings = [for port in local.unique_ports : tostring(port)]

  # Min/Max functions
  min_port = min(local.unique_ports...)
  max_port = max(local.unique_ports...)

  # Compact - remove nulls and empty strings
  valid_cidrs = compact(var.allowed_cidrs)

  # Lookup with default
  region_shortname = lookup({
    "us-east-1" = "use1"
    "us-west-2" = "usw2"
    "eu-west-1" = "euw1"
  }, var.aws_region, "unknown")

  # Keys and values
  sg_names = keys(var.security_groups)

  # Zipmap - create map from two lists
  port_descriptions = zipmap(
    local.port_strings,
    ["HTTP", "HTTPS", "Custom1", "Custom2"]
  )
}

# ============================================
# VPC with computed CIDR subnets
# ============================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(
    local.custom_tags,
    {
      Name = "${local.bucket_prefix}-vpc"
    }
  )
}

# Subnets using for_each with computed CIDRs
resource "aws_subnet" "public" {
  for_each = local.az_map

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.subnet_cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name  = format("%s-public-%s", local.bucket_prefix, each.key)
    Index = each.value.index
    Type  = "Public"
  }
}

# ============================================
# Security Groups with dynamic rules
# ============================================

resource "aws_security_group" "example" {
  for_each = var.security_groups

  name        = "${local.sanitized_owner}-${each.key}-sg"
  description = each.value.description
  vpc_id      = aws_vpc.main.id

  # Dynamic ingress using for_each over ports
  dynamic "ingress" {
    for_each = each.value.ports

    content {
      description = "${upper(each.value.protocol)} port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = each.value.protocol
      cidr_blocks = local.valid_cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${local.sanitized_owner}-${each.key}-sg"
    PortCount = length(each.value.ports)
    MinPort   = min(each.value.ports...)
    MaxPort   = max(each.value.ports...)
  }
}

# ============================================
# S3 Buckets with templatefile
# ============================================

# Create bucket policy using templatefile
resource "aws_s3_bucket" "logs" {
  bucket = "${local.bucket_prefix}-logs-${local.region_shortname}"

  tags = {
    Name    = "${local.bucket_prefix}-logs"
    Purpose = "Application Logs"
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = templatefile("${path.module}/templates/bucket-policy.json.tpl", {
    bucket_arn = aws_s3_bucket.logs.arn
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
  })
}

# ============================================
# IAM Policy using jsonencode
# ============================================

resource "aws_iam_policy" "s3_read" {
  name        = "${local.sanitized_owner}-s3-read"
  description = "Allow S3 read access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
      }
    ]
  })
}

# ============================================
# Data Sources
# ============================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================
# Null Resource with triggers (function demo)
# ============================================

resource "null_resource" "example" {
  triggers = {
    # MD5 hash of combined values
    config_hash = md5(jsonencode({
      vpc_cidr    = var.vpc_cidr
      environment = var.environment
      ports       = local.unique_ports
    }))

    # SHA256 for sensitive data
    sensitive_hash = sha256(var.owner_tag)

    # UUID for uniqueness
    unique_id = uuid()

    # Timestamp
    last_updated = timestamp()
  }
}
