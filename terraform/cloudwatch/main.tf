# CloudWatch Dashboards
resource "aws_cloudwatch_dashboard" "dashboard" {
  for_each = var.dashboards
  
  dashboard_name = each.value.name
  dashboard_body = each.value.dashboard_body
  
  tags = merge(
    var.common_tags,
    each.value.tags != null ? each.value.tags : {},
    {
      Name        = each.value.name
      DashboardId = each.key
      Type        = each.value.type != null ? each.value.type : "custom"
    }
  )
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
  alarm_description   = each.value.alarm_description != null ? each.value.alarm_description : "CloudWatch alarm for ${each.value.metric_name}"
  alarm_actions       = each.value.alarm_actions != null ? each.value.alarm_actions : []
  ok_actions          = each.value.ok_actions != null ? each.value.ok_actions : []
  insufficient_data_actions = each.value.insufficient_data_actions != null ? each.value.insufficient_data_actions : []
  
  # Dimensions
  dynamic "dimension" {
    for_each = each.value.dimensions != null ? each.value.dimensions : []
    content {
      name  = dimension.value.name
      value = dimension.value.value
    }
  }
  
  # Extended statistics
  extended_statistic = each.value.extended_statistic != null ? each.value.extended_statistic : null
  
  # Threshold metric
  dynamic "threshold_metric_id" {
    for_each = each.value.threshold_metric_id != null ? [each.value.threshold_metric_id] : []
    content {
      threshold_metric_id = threshold_metric_id.value
    }
  }
  
  # Treat missing data
  treat_missing_data = each.value.treat_missing_data != null ? each.value.treat_missing_data : "missing"
  
  # Unit
  unit = each.value.unit != null ? each.value.unit : null
  
  # Datapoints to alarm
  datapoints_to_alarm = each.value.datapoints_to_alarm != null ? each.value.datapoints_to_alarm : null
  
  # Evaluation periods
  evaluation_periods = each.value.evaluation_periods
  
  tags = merge(
    var.common_tags,
    each.value.tags != null ? each.value.tags : {},
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
  
  # Input transformer
  dynamic "input_transformer" {
    for_each = each.value.input_transformer != null ? [each.value.input_transformer] : []
    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }
  
  # Run command targets
  dynamic "run_command_targets" {
    for_each = each.value.run_command_targets != null ? each.value.run_command_targets : []
    content {
      key    = run_command_targets.value.key
      values = run_command_targets.value.values
    }
  }
  
  # ECS targets
  dynamic "ecs_target" {
    for_each = each.value.ecs_target != null ? [each.value.ecs_target] : []
    content {
      task_count          = ecs_target.value.task_count != null ? ecs_target.value.task_count : 1
      task_definition_arn = ecs_target.value.task_definition_arn
      launch_type         = ecs_target.value.launch_type != null ? ecs_target.value.launch_type : "FARGATE"
      platform_version    = ecs_target.value.platform_version != null ? ecs_target.value.platform_version : "LATEST"
      group               = ecs_target.value.group != null ? ecs_target.value.group : null
      
      dynamic "network_configuration" {
        for_each = ecs_target.value.network_configuration != null ? [ecs_target.value.network_configuration] : []
        content {
          subnets          = network_configuration.value.subnets
          security_groups  = network_configuration.value.security_groups != null ? network_configuration.value.security_groups : []
          assign_public_ip = network_configuration.value.assign_public_ip != null ? network_configuration.value.assign_public_ip : false
        }
      }
    }
  }
  
  # Lambda targets
  dynamic "lambda_target" {
    for_each = each.value.lambda_target != null ? [each.value.lambda_target] : []
    content {
      lambda_target = lambda_target.value
    }
  }
  
  # SQS targets
  dynamic "sqs_target" {
    for_each = each.value.sqs_target != null ? [each.value.sqs_target] : []
    content {
      message_group_id = sqs_target.value.message_group_id
    }
  }
} 