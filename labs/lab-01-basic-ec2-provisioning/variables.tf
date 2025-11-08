# Input Variables for Lab 01
#
# Variables allow you to parameterize your Terraform configurations,
# making them reusable and flexible across different environments.

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^(us|eu|ap|sa|ca|me|af)-(north|south|east|west|central|northeast|southeast)-[1-9]$", var.aws_region))
    error_message = "Must be a valid AWS region name."
  }
}

variable "owner_tag" {
  description = "Owner tag for resources (required by sandbox account)"
  type        = string
  default     = "jakub.ejnik"

  validation {
    condition     = length(var.owner_tag) > 0
    error_message = "Owner tag cannot be empty."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t2.small", "t3.micro", "t3.small"], var.instance_type)
    error_message = "Instance type must be a Free Tier eligible type."
  }
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.allowed_ssh_cidr) > 0
    error_message = "At least one CIDR block must be specified."
  }
}
