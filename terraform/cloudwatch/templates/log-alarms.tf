# Log-Based Alarm Monitoring Template
# This template provides monitoring for CloudWatch Logs with metric filters and transformations

# Convert single items to maps for consistent processing
locals {
  # Convert single log alarm to map format
  single_log_alarm_map = var.default_monitoring.log_alarm != null ? {
    "single-log-alarm" = var.default_monitoring.log_alarm
  } : {}
  
  # Merge single items with maps
  all_log_alarms = merge(local.single_log_alarm_map, var.default_monitoring.log_alarms)
}

# Generate CloudWatch Log Metric Filters
locals {
  log_metric_filters = merge([
    for alarm_key, alarm_config in local.all_log_alarms : {
      "${alarm_key}-metric-filter" = {
        name           = "${alarm_config.transformation_name}-metric-filter"
        pattern        = alarm_config.pattern
        log_group_name = alarm_config.log_group_name
        
        metric_transformation {
          name          = alarm_config.transformation_name
          namespace     = alarm_config.transformation_namespace
          value         = alarm_config.transformation_value
          default_value = alarm_config.default_value != null ? alarm_config.default_value : "0"
        }
      }
    }
  ]...)
}

# Generate alarms from log metric filters
locals {
  log_based_alarms = merge([
    for alarm_key, alarm_config in local.all_log_alarms : {
      "${alarm_key}-alarm" = {
        alarm_name          = "${alarm_config.severity != null ? alarm_config.severity : "Sev2"}/${coalesce(alarm_config.customer, var.customer)}/${coalesce(alarm_config.team, var.team)}/CloudWatch/Logs/${alarm_config.sub_service != null ? alarm_config.sub_service : "Custom"}/${alarm_config.error_details != null ? alarm_config.error_details : "log-pattern-detected"}"
        alarm_description   = alarm_config.alarm_description
        comparison_operator = alarm_config.comparison_operator
        evaluation_periods  = alarm_config.evaluation_periods
        metric_name         = alarm_config.transformation_name
        namespace           = alarm_config.transformation_namespace
        period              = alarm_config.period
        statistic           = alarm_config.statistic
        threshold           = alarm_config.threshold
        treat_missing_data  = alarm_config.treat_missing_data != null ? alarm_config.treat_missing_data : "notBreaching"
        unit                = alarm_config.unit != null ? alarm_config.unit : "Count"
        alarm_actions       = alarm_config.alarm_actions != null ? alarm_config.alarm_actions : []
        ok_actions          = alarm_config.ok_actions != null ? alarm_config.ok_actions : []
        insufficient_data_actions = alarm_config.insufficient_data_actions != null ? alarm_config.insufficient_data_actions : []
        dimensions          = alarm_config.dimensions != null ? alarm_config.dimensions : []
      }
    }
  ]...)
}

# Generate dashboard widgets for log-based alarms
locals {
  log_alarm_dashboard_widgets = [
    for alarm_key, alarm_config in local.all_log_alarms : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          [alarm_config.transformation_namespace, alarm_config.transformation_name]
        ]
        period = alarm_config.period
        stat   = alarm_config.statistic
        region = var.region
        title  = "${alarm_config.transformation_name} - ${alarm_config.log_group_name}"
      }
    }
  ]
  
  log_alarm_summary_widgets = [
    for alarm_key, alarm_config in local.all_log_alarms : {
      type   = "log"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = {
        query   = "SOURCE '${alarm_config.log_group_name}'\n| filter ${alarm_config.pattern}\n| stats count() by bin(5m)"
        region  = var.region
        title   = "${alarm_config.transformation_name} - Log Pattern Count"
        view    = "timeSeries"
      }
    }
  ]
}
