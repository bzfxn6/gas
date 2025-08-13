# S3 Buckets Monitoring Locals
# This file contains all S3 buckets-related alarm definitions

locals {
  # Generate S3 buckets alarms with dynamic naming
  s3_alarms = merge([
    for s3_key, s3_config in local.all_s3_buckets : {
      for alarm_key, alarm_config in {
        bucket_size = {
          alarm_name = "Sev2/${coalesce(try(s3_config.customer, null), var.customer)}/${coalesce(try(s3_config.team, null), var.team)}/S3/BucketSize/bucket-size-above-100gb"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "BucketSizeBytes"
          namespace = "AWS/S3"
          period = 300
          statistic = "Average"
          threshold = 107374182400
          alarm_description = "S3 bucket size is above 100GB"
          treat_missing_data = "notBreaching"
          unit = "Bytes"
          severity = "Sev2"
          sub_service = "BucketSize"
          error_details = "bucket-size-above-100gb"
        }
        number_of_objects = {
          alarm_name = "Sev2/${coalesce(try(s3_config.customer, null), var.customer)}/${coalesce(try(s3_config.team, null), var.team)}/S3/Objects/number-of-objects-above-1-million"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "NumberOfObjects"
          namespace = "AWS/S3"
          period = 300
          statistic = "Average"
          threshold = 1000000
          alarm_description = "S3 bucket has more than 1 million objects"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "Objects"
          error_details = "number-of-objects-above-1-million"
        }
        all_requests = {
          alarm_name = "Sev2/${coalesce(try(s3_config.customer, null), var.customer)}/${coalesce(try(s3_config.team, null), var.team)}/S3/Requests/all-requests-above-1000-per-minute"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "AllRequests"
          namespace = "AWS/S3"
          period = 300
          statistic = "Sum"
          threshold = 1000
          alarm_description = "S3 bucket has more than 1000 requests per minute"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "Requests"
          error_details = "all-requests-above-1000-per-minute"
        }
        errors_4xx = {
          alarm_name = "Sev1/${coalesce(try(s3_config.customer, null), var.customer)}/${coalesce(try(s3_config.team, null), var.team)}/S3/Errors/4xx-errors-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "4xxError"
          namespace = "AWS/S3"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "S3 bucket has 4xx errors"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "Errors"
          error_details = "4xx-errors-above-threshold"
        }
        errors_5xx = {
          alarm_name = "Sev1/${coalesce(try(s3_config.customer, null), var.customer)}/${coalesce(try(s3_config.team, null), var.team)}/S3/Errors/5xx-errors-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "5xxError"
          namespace = "AWS/S3"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "S3 bucket has 5xx errors"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "Errors"
          error_details = "5xx-errors-above-threshold"
        }
      } : "${s3_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "BucketName"
          value = s3_config.name
        }]
      })
    }
  ]...)
}
