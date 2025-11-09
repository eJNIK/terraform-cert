# ============================================
# Data Source Outputs
# ============================================

output "account_id" {
  description = "AWS Account ID from data source"
  value       = data.aws_caller_identity.current.account_id
}

output "region_name" {
  description = "Current region name from data source"
  value       = data.aws_region.current.name
}

output "available_azs" {
  description = "All available AZs from data source"
  value       = data.aws_availability_zones.available.names
}

output "amazon_linux_ami" {
  description = "Latest Amazon Linux 2023 AMI"
  value = {
    id           = data.aws_ami.amazon_linux_2023.id
    name         = data.aws_ami.amazon_linux_2023.name
    creation_date = data.aws_ami.amazon_linux_2023.creation_date
  }
}

output "ubuntu_ami" {
  description = "Latest Ubuntu 22.04 AMI"
  value = {
    id   = data.aws_ami.ubuntu.id
    name = data.aws_ami.ubuntu.name
  }
}

# ============================================
# For_Each Outputs
# ============================================

output "s3_bucket_names" {
  description = "S3 bucket names created with for_each"
  value       = { for k, v in aws_s3_bucket.example : k => v.id }
}

output "security_group_ids" {
  description = "Security group IDs created with for_each"
  value       = { for k, v in aws_security_group.example : k => v.id }
}

# ============================================
# Count Outputs
# ============================================

output "iam_user_names" {
  description = "IAM users created with count"
  value       = aws_iam_user.example[*].name
}

output "iam_user_arns" {
  description = "IAM user ARNs"
  value       = aws_iam_user.example[*].arn
}

# ============================================
# Summary
# ============================================

output "resources_summary" {
  description = "Summary of resources created"
  value = {
    s3_buckets         = length(aws_s3_bucket.example)
    security_groups    = length(aws_security_group.example)
    iam_users          = length(aws_iam_user.example)
    versioned_buckets  = length(aws_s3_bucket_versioning.example)
  }
}
