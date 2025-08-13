# SQS Monitoring Locals
# This file contains all SQS-related alarm definitions

locals {
  # Generate SQS alarms with dynamic naming
  sqs_alarms = merge([
    for sqs_key, sqs_config in local.all_sqs_queues : {
      for alarm_key, alarm_config in {
        queue_depth = {
          alarm_name = "Sev2/${coalesce(try(sqs_config.customer, null), var.customer)}/${coalesce(try(sqs_config.team, null), var.team)}/SQS/QueueDepth/queue-depth-above-1000"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "ApproximateNumberOfVisibleMessages"
          namespace = "AWS/SQS"
          period = 300
          statistic = "Average"
          threshold = 1000
          alarm_description = "SQS queue depth is above 1000 messages"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "QueueDepth"
          error_details = "queue-depth-above-1000"
        }
      } : "${sqs_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "QueueName"
          value = sqs_config.name
        }]
      })
    }
  ]...)
}

