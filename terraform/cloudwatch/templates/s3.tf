# S3 Monitoring Template
# This template provides default monitoring for AWS S3 buckets

# Default S3 monitoring configuration
locals {
  s3_alarms = {
    bucket_size_bytes = {
      alarm_name          = "s3-bucket-size-bytes"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "BucketSizeBytes"
      namespace           = "AWS/S3"
      period              = 86400  # 24 hours for S3 metrics
      statistic           = "Average"
      threshold           = 1000000000000  # 1TB in bytes
      alarm_description   = "S3 bucket size is above 1TB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    number_of_objects = {
      alarm_name          = "s3-number-of-objects"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "NumberOfObjects"
      namespace           = "AWS/S3"
      period              = 86400  # 24 hours for S3 metrics
      statistic           = "Average"
      threshold           = 10000000  # 10 million objects
      alarm_description   = "S3 bucket has more than 10 million objects"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    all_requests = {
      alarm_name          = "s3-all-requests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "AllRequests"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 10000  # 10,000 requests per 5 minutes
      alarm_description   = "S3 bucket has more than 10,000 requests per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    get_requests = {
      alarm_name          = "s3-get-requests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "GetRequests"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 8000  # 8,000 GET requests per 5 minutes
      alarm_description   = "S3 bucket has more than 8,000 GET requests per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    put_requests = {
      alarm_name          = "s3-put-requests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "PutRequests"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 2000  # 2,000 PUT requests per 5 minutes
      alarm_description   = "S3 bucket has more than 2,000 PUT requests per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    delete_requests = {
      alarm_name          = "s3-delete-requests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "DeleteRequests"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 100  # 100 DELETE requests per 5 minutes
      alarm_description   = "S3 bucket has more than 100 DELETE requests per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    head_requests = {
      alarm_name          = "s3-head-requests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "HeadRequests"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 5000  # 5,000 HEAD requests per 5 minutes
      alarm_description   = "S3 bucket has more than 5,000 HEAD requests per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    post_requests = {
      alarm_name          = "s3-post-requests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "PostRequests"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000  # 1,000 POST requests per 5 minutes
      alarm_description   = "S3 bucket has more than 1,000 POST requests per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    list_requests = {
      alarm_name          = "s3-list-requests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ListRequests"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 3000  # 3,000 LIST requests per 5 minutes
      alarm_description   = "S3 bucket has more than 3,000 LIST requests per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    bytes_downloaded = {
      alarm_name          = "s3-bytes-downloaded"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "BytesDownloaded"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000000000  # 1GB per 5 minutes
      alarm_description   = "S3 bucket has more than 1GB downloaded per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    bytes_uploaded = {
      alarm_name          = "s3-bytes-uploaded"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "BytesUploaded"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 500000000  # 500MB per 5 minutes
      alarm_description   = "S3 bucket has more than 500MB uploaded per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    first_byte_latency = {
      alarm_name          = "s3-first-byte-latency"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "FirstByteLatency"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Average"
      threshold           = 1000  # 1 second in milliseconds
      alarm_description   = "S3 bucket first byte latency is above 1 second"
      treat_missing_data = "notBreaching"
      unit                = "Milliseconds"
    }
    total_request_latency = {
      alarm_name          = "s3-total-request-latency"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "TotalRequestLatency"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Average"
      threshold           = 2000  # 2 seconds in milliseconds
      alarm_description   = "S3 bucket total request latency is above 2 seconds"
      treat_missing_data = "notBreaching"
      unit                = "Milliseconds"
    }
    errors_4xx = {
      alarm_name          = "s3-errors-4xx"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "4xxErrors"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 100  # 100 4xx errors per 5 minutes
      alarm_description   = "S3 bucket has more than 100 4xx errors per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    errors_5xx = {
      alarm_name          = "s3-errors-5xx"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "5xxErrors"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 50  # 50 5xx errors per 5 minutes
      alarm_description   = "S3 bucket has more than 50 5xx errors per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    replication_latency = {
      alarm_name          = "s3-replication-latency"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ReplicationLatency"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Average"
      threshold           = 300000  # 5 minutes in milliseconds
      alarm_description   = "S3 bucket replication latency is above 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Milliseconds"
    }
    replication_bytes_pending = {
      alarm_name          = "s3-replication-bytes-pending"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ReplicationBytesPending"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000000000  # 1GB pending replication
      alarm_description   = "S3 bucket has more than 1GB pending replication"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    replication_operations_pending = {
      alarm_name          = "s3-replication-operations-pending"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ReplicationOperationsPending"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000  # 1,000 pending replication operations
      alarm_description   = "S3 bucket has more than 1,000 pending replication operations"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    multipart_upload_count = {
      alarm_name          = "s3-multipart-upload-count"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "MultipartUploadCount"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 100  # 100 multipart uploads per 5 minutes
      alarm_description   = "S3 bucket has more than 100 multipart uploads per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    multipart_upload_parts = {
      alarm_name          = "s3-multipart-upload-parts"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "MultipartUploadParts"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000  # 1,000 multipart upload parts per 5 minutes
      alarm_description   = "S3 bucket has more than 1,000 multipart upload parts per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    multipart_upload_bytes = {
      alarm_name          = "s3-multipart-upload-bytes"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "MultipartUploadBytes"
      namespace           = "AWS/S3"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000000000  # 1GB multipart upload bytes per 5 minutes
      alarm_description   = "S3 bucket has more than 1GB multipart upload bytes per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
  }
}

# Generate alarms for S3 buckets
locals {
  s3_monitoring = merge([
    for s3_key, s3_config in local.all_s3_buckets : {
      for alarm_key, alarm_config in local.s3_alarms : "${s3_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${s3_config.name}-${alarm_config.alarm_name}"
        dimensions = [
          {
            name  = "BucketName"
            value = s3_config.name
          }
        ]
      })
      # Filter alarms based on user selection
      if length(s3_config.alarms) == 0 || contains(s3_config.alarms, alarm_key)
      # Exclude alarms if specified
      if !contains(coalesce(s3_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}

# Generate default dashboard widgets for S3 buckets
locals {
  s3_dashboard_widgets = [
    for s3_key, s3_config in local.all_s3_buckets : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/S3", "BucketSizeBytes", "BucketName", s3_config.name, "StorageType", "StandardStorage"],
          [".", ".", ".", ".", ".", "StandardIAStorage"],
          [".", ".", ".", ".", ".", "OneZoneIAStorage"],
          [".", ".", ".", ".", ".", "IntelligentTieringStorage"],
          [".", ".", ".", ".", ".", "GlacierStorage"],
          [".", ".", ".", ".", ".", "DeepArchiveStorage"]
        ]
        period = 86400  # 24 hours for S3 metrics
        stat   = "Average"
        region = var.region
        title  = "${s3_config.name} S3 Bucket Size by Storage Type"
      }
    }
  ]
}

# Generate request metrics widgets for S3 buckets
locals {
  s3_request_widgets = [
    for s3_key, s3_config in local.all_s3_buckets : {
      type   = "metric"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/S3", "AllRequests", "BucketName", s3_config.name],
          [".", "GetRequests", ".", "."],
          [".", "PutRequests", ".", "."],
          [".", "DeleteRequests", ".", "."],
          [".", "HeadRequests", ".", "."],
          [".", "PostRequests", ".", "."],
          [".", "ListRequests", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${s3_config.name} S3 Request Metrics"
      }
    }
  ]
}

# Generate data transfer widgets for S3 buckets
locals {
  s3_transfer_widgets = [
    for s3_key, s3_config in local.all_s3_buckets : {
      type   = "metric"
      x      = 0
      y      = 6
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/S3", "BytesDownloaded", "BucketName", s3_config.name],
          [".", "BytesUploaded", ".", "."],
          [".", "NumberOfObjects", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${s3_config.name} S3 Data Transfer & Object Count"
      }
    }
  ]
}

# Generate performance widgets for S3 buckets
locals {
  s3_performance_widgets = [
    for s3_key, s3_config in local.all_s3_buckets : {
      type   = "metric"
      x      = 12
      y      = 6
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/S3", "FirstByteLatency", "BucketName", s3_config.name],
          [".", "TotalRequestLatency", ".", "."],
          [".", "4xxErrors", ".", "."],
          [".", "5xxErrors", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${s3_config.name} S3 Performance & Error Metrics"
      }
    }
  ]
}

# Generate replication widgets for S3 buckets
locals {
  s3_replication_widgets = [
    for s3_key, s3_config in local.all_s3_buckets : {
      type   = "metric"
      x      = 0
      y      = 12
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/S3", "ReplicationLatency", "BucketName", s3_config.name],
          [".", "ReplicationBytesPending", ".", "."],
          [".", "ReplicationOperationsPending", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${s3_config.name} S3 Replication Metrics"
      }
    }
  ]
}

# Generate multipart upload widgets for S3 buckets
locals {
  s3_multipart_widgets = [
    for s3_key, s3_config in local.all_s3_buckets : {
      type   = "metric"
      x      = 12
      y      = 12
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/S3", "MultipartUploadCount", "BucketName", s3_config.name],
          [".", "MultipartUploadParts", ".", "."],
          [".", "MultipartUploadBytes", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${s3_config.name} S3 Multipart Upload Metrics"
      }
    }
  ]
}
