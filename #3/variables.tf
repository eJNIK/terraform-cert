variable "regions" {
  description = "Multi-region configuration"
  type = map(object({
    region            = string
    backup_retention  = number
    dynamodb_rcu      = number
    dynamodb_wcu      = number
    alert_email       = string
  }))

  default = {
    us = {
      region           = "us-east-1"
      backup_retention = 90
      dynamodb_rcu     = 10
      dynamodb_wcu     = 5
      alert_email      = "ops-us@example.com"
    }
    # ... reszta regionów
  }
}
