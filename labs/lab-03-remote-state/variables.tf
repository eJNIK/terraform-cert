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
