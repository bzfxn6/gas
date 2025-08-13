# Log-Based Alarms Monitoring Locals
# This file contains all log-based alarm definitions

locals {
  # Generate log-based alarms with dynamic naming
  log_alarms = merge([
    for log_key, log_config in local.all_log_alarms : {
      for alarm_key, alarm_config in {
        log_errors = {
          alarm_name = "Sev1/${coalesce(try(log_config.customer, null), var.customer)}/${coalesce(try(log_config.team, null), var.team)}/Logs/Errors/log-errors-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = log_config.transformation_name
          namespace = log_config.transformation_namespace
          period = 300
          statistic = "Sum"
          threshold = try(log_config.threshold, 1)
          alarm_description = "Log errors detected in ${log_config.log_group_name}"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "Errors"
          error_details = "log-errors-above-threshold"
        }
        log_warnings = {
          alarm_name = "Sev2/${coalesce(try(log_config.customer, null), var.customer)}/${coalesce(try(log_config.team, null), var.team)}/Logs/Warnings/log-warnings-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = log_config.transformation_name
          namespace = log_config.transformation_namespace
          period = 300
          statistic = "Sum"
          threshold = try(log_config.threshold, 5)
          alarm_description = "Log warnings detected in ${log_config.log_group_name}"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "Warnings"
          error_details = "log-warnings-above-threshold"
        }
        log_patterns = {
          alarm_name = "Sev2/${coalesce(try(log_config.customer, null), var.customer)}/${coalesce(try(log_config.team, null), var.team)}/Logs/Patterns/log-patterns-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = log_config.transformation_name
          namespace = log_config.transformation_namespace
          period = 300
          statistic = "Sum"
          threshold = try(log_config.threshold, 10)
          alarm_description = "Log patterns detected in ${log_config.log_group_name}"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "Patterns"
          error_details = "log-patterns-above-threshold"
        }
      } : "${log_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "LogGroupName"
          value = log_config.log_group_name
        }]
      })
    }
  ]...)
}
