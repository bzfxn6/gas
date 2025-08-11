# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "s3_lifecycle_config" {
  for_each = var.website ? {} : var.buckets
  bucket   = each.key

  rule {
    id     = "expiry-after-${lookup(each.value, "lifecycle_expiration_days", 30)}-days"
    status = lookup(each.value, "lifecycle_expiration_days") > 0 || lookup(each.value, "newer_noncurrent_expiration_versions") != null ? "Enabled" : "Disabled"

    filter {
      prefix = lookup(each.value, "lifecycle_prefix", "")
    }

    expiration {
      days = lookup(each.value, "lifecycle_expiration_days")
    }

    dynamic "noncurrent_version_expiration" {
      for_each = lookup(each.value, "noncurrent_version_expiration_days") != null || lookup(each.value, "newer_noncurrent_expiration_versions") != null ? [each.value] : []
      content {
        noncurrent_days           = lookup(each.value, "noncurrent_version_expiration_days", 1)
        newer_noncurrent_versions = lookup(each.value, "newer_noncurrent_expiration_versions")
      }
    }
  }
} 