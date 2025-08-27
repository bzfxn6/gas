# CloudWatch Module using Local Files
# This module uses separate local files for each service type

# Resource definitions
locals {
  all_databases = try(var.default_monitoring.databases, {})
  all_lambdas = try(var.default_monitoring.lambdas, {})
  all_sqs_queues = try(var.default_monitoring.sqs_queues, {})
  all_ecs_services = try(var.default_monitoring.ecs_services, {})
  all_eks_clusters = try(var.default_monitoring.eks_clusters, {})
  all_eks_pods = try(var.default_monitoring.eks_pods, {})
  all_eks_services = try(var.default_monitoring.eks_services, {})
  all_eks_volumes = try(var.default_monitoring.eks_volumes, {})
  all_eks_nodes = try(var.default_monitoring.eks_nodes, {})
  all_eks_asgs = try(var.default_monitoring.eks_asgs, {})
  all_eks_nodegroups = try(var.default_monitoring.eks_nodegroups, {})
  all_step_functions = try(var.default_monitoring.step_functions, {})
  all_ec2_instances = try(var.default_monitoring.ec2_instances, {})
  all_s3_buckets = try(var.default_monitoring.s3_buckets, {})
  all_eventbridge_rules = try(var.default_monitoring.eventbridge_rules, {})
  all_log_alarms = try(var.default_monitoring.log_alarms, {})
  
  # Merge all alarms from separate local files
  all_alarms = merge(
    local.database_alarms,
    local.lambda_alarms,
    local.sqs_alarms,
    local.eks_cluster_alarms,
    local.ecs_alarms,
    local.eks_pod_alarms,
    local.eks_service_alarms,
    local.eks_volume_alarms,
    local.eks_node_alarms,
    local.eks_asg_alarms,
    local.eks_nodegroup_alarms,
    local.step_function_alarms,
    local.ec2_alarms,
    local.s3_alarms,
    local.eventbridge_alarms,
    local.log_alarms,
    var.alarms
  )
}

# Create CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "alarms" {
  for_each = local.all_alarms

  alarm_name          = each.value.alarm_name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  treat_missing_data  = each.value.treat_missing_data
  unit                = each.value.unit

  dimensions = try(
    {
      for dim in each.value.dimensions : dim.name => dim.value
    },
    {}
  )

  tags = merge(
    {
      Name        = each.value.alarm_name
      Service     = split("/", each.value.alarm_name)[3]
      SubService  = try(each.value.sub_service, "Unknown")
      Severity    = try(each.value.severity, "Unknown")
      ErrorDetail = try(each.value.error_details, "Unknown")
    },
    var.tags
  )
}

# Create CloudWatch dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = var.dashboard_name
  dashboard_body = jsonencode({
    widgets = [
      for alarm_key, alarm_config in local.all_alarms : {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              alarm_config.namespace,
              alarm_config.metric_name,
              try(alarm_config.dimensions[0].name, "Service"),
              try(alarm_config.dimensions[0].value, "Unknown")
            ]
          ]
          period = alarm_config.period
          stat   = alarm_config.statistic
          region = data.aws_region.current.id
          title  = alarm_config.alarm_name
        }
      }
    ]
  })
}

# Data source for current region
data "aws_region" "current" {}
