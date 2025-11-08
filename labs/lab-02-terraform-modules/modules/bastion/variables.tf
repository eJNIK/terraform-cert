variable "owner_tag" {
  description = "Owner tag for resources (required by sandbox account)"
  type        = string
  default     = "jakub.ejnik"

  validation {
    condition     = length(var.owner_tag) > 0
    error_message = "Owner tag cannot be empty."
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
variable "instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = length(var.instance_type) > 0
    error_message = "Instance type cannot be empty."
  }
}

variable "ami_id" {
  description = "AMI ID for the bastion host"
  type        = string

  validation {
    condition     = length(var.ami_id) > 0
    error_message = "AMI ID cannot be empty."
  }
}

variable "public_subnet_id" {
  description = "Public Subnet ID where the bastion host will be deployed"
  type        = string

  validation {
    condition     = length(var.public_subnet_id) > 0
    error_message = "Public Subnet ID cannot be empty."
  }
}

variable "vpc_id" {
  description = "VPC ID where the bastion host will be deployed"
  type        = string

  validation {
    condition     = length(var.vpc_id) > 0
    error_message = "VPC ID cannot be empty."
  }

}
