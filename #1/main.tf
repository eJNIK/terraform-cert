module "buckets" {
    source = "./modules/s3-logging-bucket"

    for_each = {
        dev     = { bucket_name = "myapp-logs-dev-us-east-1",     retention_days = 30 }
        staging = { bucket_name = "myapp-logs-staging-us-east-1", retention_days = 60 }
        prod    = { bucket_name = "myapp-logs-prod-us-east-1",    retention_days = 90 }
    }

    bucket_name    = each.value.bucket_name
    environment    = each.key
}
