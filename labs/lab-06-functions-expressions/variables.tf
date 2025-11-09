variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "owner_tag" {
  description = "Owner tag for resources"
  type        = string
  default     = "jakub.ejnik"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.6.0.0/16"
}

variable "allowed_cidrs" {
  description = "List of allowed CIDR blocks"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12"]
}

variable "additional_ports" {
  description = "Additional ports to allow"
  type        = list(number)
  default     = [8080, 8443]
}

variable "extra_tags" {
  description = "Extra tags to merge"
  type        = map(string)
  default = {
    Project = "TerraformCert"
    Team    = "DevOps"
  }
}

variable "security_groups" {
  description = "Map of security groups with their configurations"
  type = map(object({
    description = string
    ports       = list(number)
    protocol    = string
  }))
  default = {
    web = {
      description = "Web servers"
      ports       = [80, 443]
      protocol    = "tcp"
    }
    app = {
      description = "Application servers"
      ports       = [8080, 8443, 9090]
      protocol    = "tcp"
    }
  }
}
