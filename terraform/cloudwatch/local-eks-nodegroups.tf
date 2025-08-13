# EKS Node Groups Monitoring Locals
# This file contains all EKS node groups-related alarm definitions

locals {
  # Generate EKS node groups alarms with dynamic naming
  eks_nodegroup_alarms = merge([
    for nodegroup_key, nodegroup_config in local.all_eks_nodegroups : {
      for alarm_key, alarm_config in {
        nodegroup_health = {
          alarm_name = "Sev1/${coalesce(try(nodegroup_config.customer, null), var.customer)}/${coalesce(try(nodegroup_config.team, null), var.team)}/EKS/NodeGroups/Health/nodegroup-health-check-failed"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "nodegroup_health_status"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 0
          alarm_description = "EKS node group health check failed"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "Health"
          error_details = "nodegroup-health-check-failed"
        }
        node_count = {
          alarm_name = "Sev1/${coalesce(try(nodegroup_config.customer, null), var.customer)}/${coalesce(try(nodegroup_config.team, null), var.team)}/EKS/NodeGroups/NodeCount/node-count-below-1"
          comparison_operator = "LessThanThreshold"
          evaluation_periods = 1
          metric_name = "node_count"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 1
          alarm_description = "EKS node group has no nodes"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "NodeCount"
          error_details = "node-count-below-1"
        }
        scaling_activity = {
          alarm_name = "Sev2/${coalesce(try(nodegroup_config.customer, null), var.customer)}/${coalesce(try(nodegroup_config.team, null), var.team)}/EKS/NodeGroups/Scaling/scaling-activity-detected"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "scaling_activity"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "EKS node group scaling activity detected"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "Scaling"
          error_details = "scaling-activity-detected"
        }
        capacity_utilization = {
          alarm_name = "Sev2/${coalesce(try(nodegroup_config.customer, null), var.customer)}/${coalesce(try(nodegroup_config.team, null), var.team)}/EKS/NodeGroups/Capacity/capacity-utilization-above-85pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "capacity_utilization"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 85
          alarm_description = "EKS node group capacity utilization is above 85%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          severity = "Sev2"
          sub_service = "Capacity"
          error_details = "capacity-utilization-above-85pct"
        }
        instance_health = {
          alarm_name = "Sev2/${coalesce(try(nodegroup_config.customer, null), var.customer)}/${coalesce(try(nodegroup_config.team, null), var.team)}/EKS/NodeGroups/InstanceHealth/unhealthy-instances-detected"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "unhealthy_instances"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "EKS node group has unhealthy instances"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "InstanceHealth"
          error_details = "unhealthy-instances-detected"
        }
      } : "${nodegroup_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "NodegroupName"
          value = nodegroup_config.name
        }, {
          name = "ClusterName"
          value = try(nodegroup_config.cluster_name, "default")
        }]
      })
    }
  ]...)
}
