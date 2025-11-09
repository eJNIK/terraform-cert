# ============================================
# String Functions Outputs
# ============================================

output "string_functions" {
  description = "Demonstrations of string functions"
  value = {
    lower              = local.bucket_prefix
    formatted          = local.formatted_name
    joined_cidrs       = local.allowed_cidrs_string
    replaced           = local.sanitized_owner
    split_azs          = local.availability_zones
  }
}

# ============================================
# Collection Functions Outputs
# ============================================

output "collection_functions" {
  description = "Demonstrations of collection functions"
  value = {
    all_ports      = local.all_ports
    unique_ports   = local.unique_ports
    port_count     = local.port_count
    first_port     = local.first_port
    min_port       = local.min_port
    max_port       = local.max_port
    merged_tags    = local.custom_tags
    sg_names       = local.sg_names
    port_map       = local.port_descriptions
  }
}

# ============================================
# Conditional Expressions Outputs
# ============================================

output "conditional_expressions" {
  description = "Results of conditional logic"
  value = {
    is_prod        = local.is_prod
    instance_type  = local.instance_type
    instance_count = local.instance_count
  }
}

# ============================================
# For Expressions Outputs
# ============================================

output "for_expressions" {
  description = "Results of for expressions"
  value = {
    az_map         = local.az_map
    filtered_envs  = local.prod_envs
    uppercase_envs = local.uppercase_envs
    flattened_rules = slice(local.all_security_rules, 0, min(3, length(local.all_security_rules)))
  }
}

# ============================================
# Resource Outputs
# ============================================

output "subnet_ids" {
  description = "Subnet IDs created with for_each"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "security_group_details" {
  description = "Security group details"
  value = {
    for k, v in aws_security_group.example : k => {
      id          = v.id
      name        = v.name
      port_count  = length(var.security_groups[k].ports)
    }
  }
}

output "s3_bucket_info" {
  description = "S3 bucket information"
  value = {
    name   = aws_s3_bucket.logs.id
    arn    = aws_s3_bucket.logs.arn
    region = aws_s3_bucket.logs.region
  }
}

# ============================================
# Function Examples Output
# ============================================

output "function_examples" {
  description = "Examples of various function results"
  value = {
    # Encoding functions
    region_shortname = local.region_shortname

    # Type conversions
    port_strings = local.port_strings

    # CIDR functions
    example_cidr_subnet = cidrsubnet(var.vpc_cidr, 8, 0)
    cidr_host_example   = cidrhost(var.vpc_cidr, 10)

    # Compact example
    valid_cidrs_count = length(local.valid_cidrs)
  }
}

# ============================================
# Splat Expression Example
# ============================================

output "splat_expression" {
  description = "Example of splat expression"
  value = {
    all_subnet_ids   = values(aws_subnet.public)[*].id
    all_subnet_cidrs = values(aws_subnet.public)[*].cidr_block
  }
}
