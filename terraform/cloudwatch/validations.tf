# Validation rules for CloudWatch module
# This file contains validation rules to catch configuration errors early

# Validate alarm names don't contain special characters
locals {
  # Check all alarm names for invalid characters
  invalid_alarm_names = [
    for alarm_key, alarm_config in var.alarms : alarm_config.alarm_name
    if !can(regex("^[a-zA-Z0-9/_-]+$", alarm_config.alarm_name))
  ]
  
  # Check customer name for invalid characters
  invalid_customer = !can(regex("^[a-zA-Z0-9_-]+$", var.customer))
  
  # Check team name for invalid characters
  invalid_team = !can(regex("^[a-zA-Z0-9_-]+$", var.team))
  
  # Check dashboard names for invalid characters
  invalid_dashboard_names = [
    for dashboard_key, dashboard_config in var.dashboards : dashboard_config.name
    if !can(regex("^[a-zA-Z0-9_-]+$", dashboard_config.name))
  ]
  
  # Check log group names for invalid characters
  invalid_log_group_names = [
    for log_group_key, log_group_config in var.log_groups : log_group_config.name
    if !can(regex("^[a-zA-Z0-9_-]+$", log_group_config.name))
  ]
  
  # Check event rule names for invalid characters
  invalid_event_rule_names = [
    for rule_key, rule_config in var.event_rules : rule_config.name
    if !can(regex("^[a-zA-Z0-9_-]+$", rule_config.name))
  ]
  
  # Check for invalid alarm configuration values
  invalid_comparison_operators = [
    for alarm_key, alarm_config in var.alarms : alarm_config.alarm_name
    if !contains(["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"], alarm_config.comparison_operator)
  ]
  
  invalid_evaluation_periods = [
    for alarm_key, alarm_config in var.alarms : alarm_config.alarm_name
    if alarm_config.evaluation_periods <= 0 || alarm_config.evaluation_periods > 10
  ]
  
  invalid_periods = [
    for alarm_key, alarm_config in var.alarms : alarm_config.alarm_name
    if alarm_config.period < 60 || alarm_config.period > 86400 || alarm_config.period % 60 != 0
  ]
  
  invalid_statistics = [
    for alarm_key, alarm_config in var.alarms : alarm_config.alarm_name
    if !contains(["SampleCount", "Average", "Sum", "Minimum", "Maximum"], alarm_config.statistic)
  ]
  
  invalid_treat_missing_data = [
    for alarm_key, alarm_config in var.alarms : alarm_config.alarm_name
    if !contains(["breaching", "notBreaching", "ignore", "missing"], alarm_config.treat_missing_data)
  ]
}

# Validation checks that will fail the plan if any are true
resource "null_resource" "validation_checks" {
  # This resource will fail to create if any validation fails
  
  lifecycle {
    precondition {
      condition = length(local.invalid_alarm_names) == 0
      error_message = "The following alarm names contain invalid characters (only alphanumeric, hyphens, underscores, and forward slashes allowed): ${join(", ", local.invalid_alarm_names)}"
    }
    
    precondition {
      condition = !local.invalid_customer
      error_message = "Customer name '${var.customer}' contains invalid characters. Only alphanumeric characters, hyphens, and underscores are allowed."
    }
    
    precondition {
      condition = !local.invalid_team
      error_message = "Team name '${var.team}' contains invalid characters. Only alphanumeric characters, hyphens, and underscores are allowed."
    }
    
    precondition {
      condition = length(local.invalid_dashboard_names) == 0
      error_message = "The following dashboard names contain invalid characters (only alphanumeric, hyphens, and underscores allowed): ${join(", ", local.invalid_dashboard_names)}"
    }
    
    precondition {
      condition = length(local.invalid_log_group_names) == 0
      error_message = "The following log group names contain invalid characters (only alphanumeric, hyphens, and underscores allowed): ${join(", ", local.invalid_log_group_names)}"
    }
    
    precondition {
      condition = length(local.invalid_event_rule_names) == 0
      error_message = "The following event rule names contain invalid characters (only alphanumeric, hyphens, and underscores allowed): ${join(", ", local.invalid_event_rule_names)}"
    }
    
    precondition {
      condition = length(local.invalid_comparison_operators) == 0
      error_message = "Invalid comparison operators found in alarms: ${join(", ", local.invalid_comparison_operators)}. Must be one of: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold"
    }
    
    precondition {
      condition = length(local.invalid_evaluation_periods) == 0
      error_message = "Invalid evaluation periods found in alarms: ${join(", ", local.invalid_evaluation_periods)}. Must be between 1 and 10"
    }
    
    precondition {
      condition = length(local.invalid_periods) == 0
      error_message = "Invalid periods found in alarms: ${join(", ", local.invalid_periods)}. Must be between 60 and 86400 seconds and a multiple of 60"
    }
    
    precondition {
      condition = length(local.invalid_statistics) == 0
      error_message = "Invalid statistics found in alarms: ${join(", ", local.invalid_statistics)}. Must be one of: SampleCount, Average, Sum, Minimum, Maximum"
    }
    
    precondition {
      condition = length(local.invalid_treat_missing_data) == 0
      error_message = "Invalid treat_missing_data values found in alarms: ${join(", ", local.invalid_treat_missing_data)}. Must be one of: breaching, notBreaching, ignore, missing"
    }
  }
}


