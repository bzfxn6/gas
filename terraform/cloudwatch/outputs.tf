# Dashboard outputs
output "dashboard_names" {
  description = "Names of the created CloudWatch dashboards"
  value       = [for k, v in aws_cloudwatch_dashboard.dashboard : v.dashboard_name]
}

output "dashboard_arns" {
  description = "ARNs of the created CloudWatch dashboards"
  value       = [for k, v in aws_cloudwatch_dashboard.dashboard : v.dashboard_arn]
}

output "dashboard_count" {
  description = "Number of CloudWatch dashboards created"
  value       = length(aws_cloudwatch_dashboard.dashboard)
}

output "dashboard_details" {
  description = "Detailed information about created CloudWatch dashboards"
  value = {
    for k, v in aws_cloudwatch_dashboard.dashboard : k => {
      name = v.dashboard_name
      arn  = v.dashboard_arn
      type = var.dashboards[k].type != null ? var.dashboards[k].type : "custom"
      linked_dashboards = var.dashboards[k].linked_dashboards != null ? var.dashboards[k].linked_dashboards : []
    }
  }
}

# Alarm outputs
output "alarm_names" {
  description = "Names of the created CloudWatch alarms"
  value       = [for k, v in aws_cloudwatch_metric_alarm.alarm : v.alarm_name]
}

output "alarm_arns" {
  description = "ARNs of the created CloudWatch alarms"
  value       = [for k, v in aws_cloudwatch_metric_alarm.alarm : v.arn]
}

output "alarm_count" {
  description = "Number of CloudWatch alarms created"
  value       = length(aws_cloudwatch_metric_alarm.alarm)
}

output "alarm_details" {
  description = "Detailed information about created CloudWatch alarms"
  value = {
    for k, v in aws_cloudwatch_metric_alarm.alarm : k => {
      name        = v.alarm_name
      arn         = v.arn
      metric_name = v.metric_name
      namespace   = v.namespace
      threshold   = v.threshold
      status      = v.state
    }
  }
}

# Log Group outputs
output "log_group_names" {
  description = "Names of the created CloudWatch log groups"
  value       = [for k, v in aws_cloudwatch_log_group.log_group : v.name]
}

output "log_group_arns" {
  description = "ARNs of the created CloudWatch log groups"
  value       = [for k, v in aws_cloudwatch_log_group.log_group : v.arn]
}

output "log_group_count" {
  description = "Number of CloudWatch log groups created"
  value       = length(aws_cloudwatch_log_group.log_group)
}

output "log_group_details" {
  description = "Detailed information about created CloudWatch log groups"
  value = {
    for k, v in aws_cloudwatch_log_group.log_group : k => {
      name              = v.name
      arn               = v.arn
      retention_in_days = v.retention_in_days
    }
  }
}

# Event Rule outputs
output "event_rule_names" {
  description = "Names of the created CloudWatch event rules"
  value       = [for k, v in aws_cloudwatch_event_rule.event_rule : v.name]
}

output "event_rule_arns" {
  description = "ARNs of the created CloudWatch event rules"
  value       = [for k, v in aws_cloudwatch_event_rule.event_rule : v.arn]
}

output "event_rule_count" {
  description = "Number of CloudWatch event rules created"
  value       = length(aws_cloudwatch_event_rule.event_rule)
}

output "event_rule_details" {
  description = "Detailed information about created CloudWatch event rules"
  value = {
    for k, v in aws_cloudwatch_event_rule.event_rule : k => {
      name                = v.name
      arn                 = v.arn
      schedule_expression = v.schedule_expression
      is_enabled          = v.is_enabled
    }
  }
}

# Event Target outputs
output "event_target_count" {
  description = "Number of CloudWatch event targets created"
  value       = length(aws_cloudwatch_event_target.event_target)
}

output "event_target_details" {
  description = "Detailed information about created CloudWatch event targets"
  value = {
    for k, v in aws_cloudwatch_event_target.event_target : k => {
      target_id = v.target_id
      rule_name = aws_cloudwatch_event_rule.event_rule[v.rule_key].name
      arn       = v.arn
    }
  }
}

# Summary outputs
output "total_resources" {
  description = "Total number of CloudWatch resources created"
  value = {
    dashboards    = length(aws_cloudwatch_dashboard.dashboard)
    alarms        = length(aws_cloudwatch_metric_alarm.alarm)
    log_groups    = length(aws_cloudwatch_log_group.log_group)
    event_rules   = length(aws_cloudwatch_event_rule.event_rule)
    event_targets = length(aws_cloudwatch_event_target.event_target)
  }
}

output "resource_summary" {
  description = "Summary of all CloudWatch resources by type"
  value = {
    dashboards = {
      count = length(aws_cloudwatch_dashboard.dashboard)
      names = [for k, v in aws_cloudwatch_dashboard.dashboard : v.dashboard_name]
    }
    alarms = {
      count = length(aws_cloudwatch_metric_alarm.alarm)
      names = [for k, v in aws_cloudwatch_metric_alarm.alarm : v.alarm_name]
    }
    log_groups = {
      count = length(aws_cloudwatch_log_group.log_group)
      names = [for k, v in aws_cloudwatch_log_group.log_group : v.name]
    }
    event_rules = {
      count = length(aws_cloudwatch_event_rule.event_rule)
      names = [for k, v in aws_cloudwatch_event_rule.event_rule : v.name]
    }
  }
} 