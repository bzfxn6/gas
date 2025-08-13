# Lambda Monitoring Locals
# This file contains all Lambda-related alarm definitions

locals {
  # Generate Lambda alarms with dynamic naming
  lambda_alarms = merge([
    for lambda_key, lambda_config in local.all_lambdas : {
      for alarm_key, alarm_config in {
        errors = {
          alarm_name = "Sev1/${coalesce(try(lambda_config.customer, null), var.customer)}/${coalesce(try(lambda_config.team, null), var.team)}/Lambda/Errors/error-rate-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "Errors"
          namespace = "AWS/Lambda"
          period = 300
          statistic = "Sum"
          threshold = 1
          alarm_description = "Lambda function has errors"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "Errors"
          error_details = "error-rate-above-threshold"
        }
        duration = {
          alarm_name = "Sev2/${coalesce(try(lambda_config.customer, null), var.customer)}/${coalesce(try(lambda_config.team, null), var.team)}/Lambda/Duration/duration-above-5-seconds"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "Duration"
          namespace = "AWS/Lambda"
          period = 300
          statistic = "Average"
          threshold = 5000
          alarm_description = "Lambda function duration is above 5 seconds"
          treat_missing_data = "notBreaching"
          unit = "Milliseconds"
          severity = "Sev2"
          sub_service = "Duration"
          error_details = "duration-above-5-seconds"
        }
        throttles = {
          alarm_name = "Sev2/${coalesce(try(lambda_config.customer, null), var.customer)}/${coalesce(try(lambda_config.team, null), var.team)}/Lambda/Throttles/throttles-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "Throttles"
          namespace = "AWS/Lambda"
          period = 300
          statistic = "Sum"
          threshold = 1
          alarm_description = "Lambda function is being throttled"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "Throttles"
          error_details = "throttles-above-threshold"
        }
      } : "${lambda_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "FunctionName"
          value = lambda_config.name
        }]
      })
    }
  ]...)
}

