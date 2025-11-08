variable "environments" {
  description = "A map of environments to deploy to"
  type = map(object({
    cost_center     = string
    owner           = string
    backup_required = bool
    region          = string
  }))

  default = {
    dev = {
      cost_center     = "DEV-001"
      owner           = "dev-team"
      backup_required = false
      region          = "us-west-1"
    }
    staging = {
      cost_center     = "STG-001"
      owner           = "qa-team"
      backup_required = true
      region          = "us-east-1"
    }
    prod = {
      cost_center     = "PRD-001"
      owner           = "ops-team"
      backup_required = true
      region          = "us-east-2"
    }
  }
}
