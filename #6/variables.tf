variable "services" {
  type = map(object({
    regions = list(object({
      name     = string
      zones    = list(string)
      replicas = number
      tier     = string # "free", "standard", "premium"
    }))
    tags        = map(string)
    environment = string
  }))

  default = {
    api = {
      environment = "prod"
      tags        = { team = "backend", critical = "true" }
      regions = [
        { name = "us-east-1", zones = ["a", "b", "c"], replicas = 5, tier = "premium" },
        { name = "eu-west-1", zones = ["a", "b"], replicas = 3, tier = "standard" }
      ]
    }
    web = {
      environment = "prod"
      tags        = { team = "frontend" }
      regions = [
        { name = "us-east-1", zones = ["a", "b"], replicas = 2, tier = "standard" },
        { name = "ap-south-1", zones = ["a"], replicas = 1, tier = "free" }
      ]
    }
    worker = {
      environment = "dev"
      tags        = { team = "backend" }
      regions = [
        { name = "us-west-2", zones = ["a"], replicas = 1, tier = "free" }
      ]
    }
  }
}
