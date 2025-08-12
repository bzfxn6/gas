# Locals for alarm processing
locals {
  # Get the actual attributes from default_monitoring
  # Use try() to handle missing attributes gracefully
  all_databases = try(var.default_monitoring.databases, {})
  all_lambdas = try(var.default_monitoring.lambdas, {})
  all_sqs_queues = try(var.default_monitoring.sqs_queues, {})
  all_ecs_services = try(var.default_monitoring.ecs_services, {})
  all_eks_clusters = try(var.default_monitoring.eks_clusters, {})
  all_eks_pods = try(var.default_monitoring.eks_pods, {})
  all_eks_nodegroups = try(var.default_monitoring.eks_nodegroups, {})
  all_step_functions = try(var.default_monitoring.step_functions, {})
  all_ec2_instances = try(var.default_monitoring.ec2_instances, {})
  all_s3_buckets = try(var.default_monitoring.s3_buckets, {})
  all_eventbridge_rules = try(var.default_monitoring.eventbridge_rules, {})
  all_log_alarms = try(var.default_monitoring.log_alarms, {})
  
  # Process log metric filters
  log_metric_filters = merge([
    for alarm_key, alarm_config in local.all_log_alarms : {
      "${alarm_key}-metric-filter" = {
        name = "${alarm_config.transformation_name}-metric-filter"
        pattern = alarm_config.pattern
        log_group_name = alarm_config.log_group_name
        metric_transformation = [{
          name = alarm_config.transformation_name
          namespace = alarm_config.transformation_namespace
          value = alarm_config.transformation_value
          default_value = alarm_config.default_value != null ? alarm_config.default_value : "0"
        }]
      }
    }
  ]...)
}

# Process all alarms from default monitoring
locals {
  # Merge all default alarms with custom alarms
  all_alarms = merge(
    # Database alarms
    merge([
      for db_key, db_config in local.all_databases : {
        for alarm_key, alarm_config in {
          cpu_utilization = {
            alarm_name = "Sev2/${coalesce(db_config.customer, var.customer)}/${coalesce(db_config.team, var.team)}/RDS/CPU/cpu-utilization-above-80%"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods = 2
            metric_name = "CPUUtilization"
            namespace = "AWS/RDS"
            period = 300
            statistic = "Average"
            threshold = 80
            alarm_description = "Database CPU utilization is above 80%"
            treat_missing_data = "notBreaching"
            unit = "Percent"
            dimensions = [{ name = "DBInstanceIdentifier", value = db_config.name }]
          }
        } : "${db_key}-${alarm_key}" => alarm_config
      }
    ]...),
    
    # EKS Cluster alarms
    merge([
      for eks_key, eks_config in local.all_eks_clusters : {
        for alarm_key, alarm_config in {
          cluster_cpu_utilization = {
            alarm_name = "Sev2/${coalesce(eks_config.customer, var.customer)}/${coalesce(eks_config.team, var.team)}/EKS/Cluster/CPU/cpu-utilization-above-80%"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods = 2
            metric_name = "node_cpu_utilization"
            namespace = "ContainerInsights"
            period = 300
            statistic = "Average"
            threshold = 80
            alarm_description = "EKS cluster CPU utilization is above 80%"
            treat_missing_data = "notBreaching"
            unit = "Percent"
            dimensions = [{ name = "ClusterName", value = eks_config.name }]
          }
        } : "${eks_key}-${alarm_key}" => alarm_config
      }
    ]...),
    
    # Custom alarms
    var.alarms
  )
}

