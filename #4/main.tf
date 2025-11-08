resource "aws_s3_bucket" "this" {
    for_each = local.bucket_names
    bucket   = each.value
    tags     = local.environment_tags[each.key]

    lifecycle {
      prevent_destroy = (each.key == "prod")
    }
}
