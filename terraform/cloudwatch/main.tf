

# CloudWatch Dashboards
resource "aws_cloudwatch_dashboard" "dashboard" {
  for_each = var.dashboards
  
  dashboard_name = each.value.name
  dashboard_body = each.value.dashboard_body
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "alarm" {
  for_each = local.all_alarms
  
  alarm_name          = each.value.alarm_name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = try(each.value.alarm_description, "CloudWatch alarm for ${each.value.metric_name}")
  alarm_actions       = try(each.value.alarm_actions, [])
  ok_actions          = try(each.value.ok_actions, [])
  insufficient_data_actions = try(each.value.insufficient_data_actions, [])
  
  # Extended statistics
  extended_statistic = try(each.value.extended_statistic, null)
  
  # Treat missing data
  treat_missing_data = try(each.value.treat_missing_data, "missing")
  
  # Unit
  unit = try(each.value.unit, null)
  
  # Datapoints to alarm
  datapoints_to_alarm = try(each.value.datapoints_to_alarm, null)
  
  tags = merge(
    var.common_tags,
    try(each.value.tags, {}),
    {
      Name      = each.value.alarm_name
      AlarmId  = each.key
      Metric   = each.value.metric_name
      Namespace = each.value.namespace
    }
  )
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "log_group" {
  for_each = var.log_groups
  
  name              = each.value.name
  retention_in_days = each.value.retention_in_days != null ? each.value.retention_in_days : 14
  kms_key_id        = each.value.kms_key_id != null ? each.value.kms_key_id : null
  
  tags = merge(
    var.common_tags,
    each.value.tags != null ? each.value.tags : {},
    {
      Name      = each.value.name
      LogGroupId = each.key
    }
  )
}

# CloudWatch Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "log_metric_filter" {
  for_each = local.log_metric_filters
  
  name           = each.value.name
  pattern        = each.value.pattern
  log_group_name = each.value.log_group_name
  
  metric_transformation {
    name          = each.value.metric_transformation[0].name
    namespace     = each.value.metric_transformation[0].namespace
    value         = each.value.metric_transformation[0].value
    default_value = each.value.metric_transformation[0].default_value
  }
}

# CloudWatch Event Rules
resource "aws_cloudwatch_event_rule" "event_rule" {
  for_each = var.event_rules
  
  name                = each.value.name
  description         = each.value.description != null ? each.value.description : "CloudWatch event rule for ${each.value.name}"
  schedule_expression = each.value.schedule_expression != null ? each.value.schedule_expression : null
  event_pattern       = each.value.event_pattern != null ? jsonencode(each.value.event_pattern) : null
  is_enabled          = each.value.is_enabled != null ? each.value.is_enabled : true
  role_arn            = each.value.role_arn != null ? each.value.role_arn : null
  
  tags = merge(
    var.common_tags,
    each.value.tags != null ? each.value.tags : {},
    {
      Name    = each.value.name
      RuleId  = each.key
    }
  )
}

# CloudWatch Event Targets
resource "aws_cloudwatch_event_target" "event_target" {
  for_each = var.event_targets
  
  rule      = aws_cloudwatch_event_rule.event_rule[each.value.rule_key].name
  target_id = each.value.target_id
  arn       = each.value.arn
  
  # Input
  input = each.value.input != null ? each.value.input : null
  input_path = each.value.input_path != null ? each.value.input_path : null
} 