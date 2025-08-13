# ECS Service Monitoring Locals
# This file contains all ECS service-related alarm definitions

locals {
  # Generate ECS service alarms with dynamic naming
  ecs_alarms = merge([
    for ecs_key, ecs_config in local.all_ecs_services : {
      for alarm_key, alarm_config in {
        cpu_utilization = {
          alarm_name = "Sev2/${coalesce(try(ecs_config.customer, null), var.customer)}/${coalesce(try(ecs_config.team, null), var.team)}/ECS/CPU/cpu-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "CPUUtilization"
          namespace = "AWS/ECS"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "ECS service CPU utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          severity = "Sev2"
          sub_service = "CPU"
          error_details = "cpu-utilization-above-80pct"
        }
        memory_utilization = {
          alarm_name = "Sev2/${coalesce(try(ecs_config.customer, null), var.customer)}/${coalesce(try(ecs_config.team, null), var.team)}/ECS/Memory/memory-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "MemoryUtilization"
          namespace = "AWS/ECS"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "ECS service memory utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          severity = "Sev2"
          sub_service = "Memory"
          error_details = "memory-utilization-above-80pct"
        }
        running_tasks = {
          alarm_name = "Sev1/${coalesce(try(ecs_config.customer, null), var.customer)}/${coalesce(try(ecs_config.team, null), var.team)}/ECS/RunningTasks/running-tasks-below-1"
          comparison_operator = "LessThanThreshold"
          evaluation_periods = 1
          metric_name = "RunningTaskCount"
          namespace = "AWS/ECS"
          period = 300
          statistic = "Average"
          threshold = 1
          alarm_description = "ECS service has no running tasks"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "RunningTasks"
          error_details = "running-tasks-below-1"
        }
      } : "${ecs_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "ServiceName"
          value = ecs_config.name
        }, {
          name = "ClusterName"
          value = try(ecs_config.cluster_name, "default")
        }]
      })
    }
  ]...)
}
