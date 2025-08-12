# Main Monitoring Template
# This template combines all monitoring templates and provides final outputs

# Convert single items to maps for consistent processing
locals {
  # Convert single database to map format
  single_database_map = var.default_monitoring.database != null ? {
    "single-database" = var.default_monitoring.database
  } : {}
  
  # Convert single lambda to map format
  single_lambda_map = var.default_monitoring.lambda != null ? {
    "single-lambda" = var.default_monitoring.lambda
  } : {}
  
  # Convert single SQS queue to map format
  single_sqs_map = var.default_monitoring.sqs_queue != null ? {
    "single-sqs-queue" = var.default_monitoring.sqs_queue
  } : {}
  
  # Convert single ECS service to map format
  single_ecs_map = var.default_monitoring.ecs_service != null ? {
    "single-ecs-service" = var.default_monitoring.ecs_service
  } : {}
  
  # Convert single EKS cluster to map format
  single_eks_cluster_map = var.default_monitoring.eks_cluster != null ? {
    "single-eks-cluster" = var.default_monitoring.eks_cluster
  } : {}
  
  # Convert single EKS pod to map format
  single_eks_pod_map = var.default_monitoring.eks_pod != null ? {
    "single-eks-pod" = var.default_monitoring.eks_pod
  } : {}
  
  # Convert single EKS node group to map format
  single_eks_nodegroup_map = var.default_monitoring.eks_nodegroup != null ? {
    "single-eks-nodegroup" = var.default_monitoring.eks_nodegroup
  } : {}
  
  # Convert single Step Function to map format
  single_step_function_map = var.default_monitoring.step_function != null ? {
    "single-step-function" = var.default_monitoring.step_function
  } : {}
  
  # Convert single EC2 instance to map format
  single_ec2_map = var.default_monitoring.ec2_instance != null ? {
    "single-ec2-instance" = var.default_monitoring.ec2_instance
  } : {}
  
  # Convert single S3 bucket to map format
  single_s3_map = var.default_monitoring.s3_bucket != null ? {
    "single-s3-bucket" = var.default_monitoring.s3_bucket
  } : {}
  
  # Convert single EventBridge rule to map format
  single_eventbridge_map = var.default_monitoring.eventbridge_rule != null ? {
    "single-eventbridge-rule" = var.default_monitoring.eventbridge_rule
  } : {}
  
  # Convert single log alarm to map format
  single_log_alarm_map = var.default_monitoring.log_alarm != null ? {
    "single-log-alarm" = var.default_monitoring.log_alarm
  } : {}
  
  # Merge single items with maps
  all_databases = merge(local.single_database_map, var.default_monitoring.databases)
  all_lambdas = merge(local.single_lambda_map, var.default_monitoring.lambdas)
  all_sqs_queues = merge(local.single_sqs_map, var.default_monitoring.sqs_queues)
  all_ecs_services = merge(local.single_ecs_map, var.default_monitoring.ecs_services)
  all_eks_clusters = merge(local.single_eks_cluster_map, var.default_monitoring.eks_clusters)
  all_eks_pods = merge(local.single_eks_pod_map, var.default_monitoring.eks_pods)
  all_eks_nodegroups = merge(local.single_eks_nodegroup_map, var.default_monitoring.eks_nodegroups)
  all_step_functions = merge(local.single_step_function_map, var.default_monitoring.step_functions)
  all_ec2_instances = merge(local.single_ec2_map, var.default_monitoring.ec2_instances)
  all_s3_buckets = merge(local.single_s3_map, var.default_monitoring.s3_buckets)
  all_eventbridge_rules = merge(local.single_eventbridge_map, var.default_monitoring.eventbridge_rules)
  all_log_alarms = merge(local.single_log_alarm_map, var.default_monitoring.log_alarms)
}

# Merge all default alarms from all templates
locals {
  all_default_alarms = merge(
    local.database_alarms,
    local.lambda_alarms,
    local.sqs_alarms,
    local.ecs_alarms,
    local.eks_cluster_monitoring,
    local.eks_pod_monitoring,
    local.eks_nodegroup_monitoring,
    local.step_function_monitoring,
    local.ec2_monitoring,
    local.s3_monitoring,
    local.eventbridge_monitoring,
    local.log_based_alarms
  )
}

# Merge all custom alarms with default alarms
locals {
  all_alarms = merge(
    local.all_default_alarms,
    var.alarms
  )
}

# Combine all dashboard widgets
locals {
  all_dashboard_widgets = concat(
    local.default_database_widgets,
    local.default_lambda_widgets,
    local.default_sqs_widgets,
    local.default_ecs_widgets,
    local.eks_cluster_dashboard_widgets,
    local.eks_pod_dashboard_widgets,
    local.eks_nodegroup_dashboard_widgets,
    local.eks_nodegroup_health_widgets,
    local.eks_nodegroup_scaling_widgets,
    local.eks_nodegroup_ec2_widgets,
    local.step_function_dashboard_widgets,
    local.step_function_activity_widgets,
    local.step_function_lambda_widgets,
    local.step_function_service_widgets,
    local.ec2_dashboard_widgets,
    local.ec2_ebs_widgets,
    local.ec2_status_widgets,
    local.s3_dashboard_widgets,
    local.s3_request_widgets,
    local.s3_transfer_widgets,
    local.s3_performance_widgets,
    local.s3_replication_widgets,
    local.s3_multipart_widgets,
    local.eventbridge_dashboard_widgets,
    local.eventbridge_delivery_widgets,
    local.eventbridge_flow_widgets,
    local.eventbridge_replay_widgets,
    local.log_alarm_dashboard_widgets,
    local.log_alarm_summary_widgets
  )
}

# Generate overview dashboard with alarm status
locals {
  overview_dashboard_body = var.dashboard_links.overview_dashboard != null ? jsonencode({
    widgets = concat(
      # Alarm status widget
      var.dashboard_links.overview_dashboard.include_all_alarms != false ? [{
        type   = "alarm"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          alarms = [for k, v in aws_cloudwatch_metric_alarm.alarm : v.arn]
          title  = "All CloudWatch Alarms Status"
        }
      }] : [],
      # Custom widgets
      var.dashboard_links.overview_dashboard.custom_widgets != null ? var.dashboard_links.overview_dashboard.custom_widgets : []
    )
  }) : null
}
