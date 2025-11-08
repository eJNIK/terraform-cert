variable "configuration" {
  type = map(object({
    instance_count    = number
    enable_monitoring = bool
    backup_schedule   = string
    deployment_region = string
  }))

  default = {

    dev = {
      instance_count    = 1
      enable_monitoring = false
      backup_schedule   = "monthly"
      deployment_region = "us-west-1"
    }

    staging = {
      instance_count    = 2
      enable_monitoring = true
      backup_schedule   = "weekly"
      deployment_region = "us-west-2"
    }

    prod = {
      instance_count    = 5
      enable_monitoring = true
      backup_schedule   = "daily"
      deployment_region = "us-east-1"
    }
  }
  validation {
    condition = alltrue([
      for k, v in var.configuration : v.instance_count >= 1
    ])
    error_message = "instance_count must be at least 1 for all environments."
  }
}
