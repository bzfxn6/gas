locals {
  bucket_notifications = {
    for bucket, values in var.buckets :
    bucket => {
      queue_arn            = lookup(values, "queue_arn", null)
      queue_events         = lookup(values, "queue_events", null)
      queue_filter_suffix  = lookup(values, "queue_filter_suffix", null)
      queue_filter_prefix  = lookup(values, "queue_filter_prefix", null)
      lambda_arn           = lookup(values, "lambda_arn", null)
      lambda_filter_suffix = lookup(values, "lambda_filter_suffix", null)
      lambda_filter_prefix = lookup(values, "lambda_filter_prefix", null)
      eventbridge_enabled  = lookup(values, "eventbridge_enabled", false)
    }
  }
}

# Queue notifications
resource "aws_s3_bucket_notification" "queue_bucket_notification" {
  for_each = {
    for bucket, values in local.bucket_notifications : bucket => values
    if values.queue_arn != null
  }

  bucket = each.key

  eventbridge = true

  queue {
    events        = each.value.queue_events
    queue_arn     = each.value.queue_arn
    filter_suffix = each.value.queue_filter_suffix
    filter_prefix = each.value.queue_filter_prefix
  }
}

# Lambda notifications
resource "aws_s3_bucket_notification" "lambda_bucket_notification" {
  for_each = {
    for bucket, values in local.bucket_notifications : bucket => values
    if values.lambda_arn != null
  }

  bucket = each.key

  eventbridge = true

  lambda_function {
    events              = each.value.queue_events
    lambda_function_arn = each.value.lambda_arn
    filter_suffix       = each.value.lambda_filter_suffix
    filter_prefix       = each.value.lambda_filter_prefix
  }
}

# EventBridge-only notifications
resource "aws_s3_bucket_notification" "eventbridge_only_notification" {
  for_each = {
    for bucket, values in local.bucket_notifications : bucket => values
    if values.eventbridge_enabled == true && values.queue_arn == null && values.lambda_arn == null
  }

  bucket = each.key

  eventbridge = true
} 