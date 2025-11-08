output "bucket_arns" {
  description = "ARNs of all S3 buckets"
  value = {
    for k, v in aws_s3_bucket.this : k => v.arn
  }
}

output "bucket_names" {
  value = local.bucket_names
}

output "bucket_summary" {
  description = "Formatted summary of all buckets with tags"
  value = join("\n", [
    for env, bucket in aws_s3_bucket.this :
    "Environment: ${env} | Bucket: ${bucket.bucket} | Owner: ${bucket.tags["Owner"]} | Region: ${var.environments[env].region}"
  ])
}
