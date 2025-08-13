# EKS Cluster Monitoring Template
# This template provides default monitoring for EKS clusters with short_name support

# Generate alarms for EKS clusters with short_name support
locals {
  eks_cluster_alarms = merge([
    for eks_key, eks_config in local.all_eks_clusters : {
      for alarm_key, alarm_config in {
        cpu_utilization = {
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "/${eks_config.short_name}" : ""}/Cluster/CPU/cpu-utilization-above-80pct"
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
        memory_utilization = {
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "/${eks_config.short_name}" : ""}/Cluster/Memory/memory-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "node_memory_utilization"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "EKS cluster memory utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }
        disk_utilization = {
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "/${eks_config.short_name}" : ""}/Cluster/Disk/disk-utilization-above-85pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "node_filesystem_utilization"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Average"
          threshold = 85
          alarm_description = "EKS cluster disk utilization is above 85%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }
        pod_count = {
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "/${eks_config.short_name}" : ""}/Cluster/Pods/pod-count-above-100"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "pod_number_of_running_containers"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Sum"
          threshold = 100
          alarm_description = "EKS cluster has more than 100 running pods"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }
        node_count = {
          alarm_name = "Sev1/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "/${eks_config.short_name}" : ""}/Cluster/Nodes/node-count-below-2"
          comparison_operator = "LessThanThreshold"
          evaluation_periods = 1
          metric_name = "cluster_node_count"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Average"
          threshold = 2
          alarm_description = "EKS cluster has fewer than 2 nodes"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }
        network_rx = {
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "/${eks_config.short_name}" : ""}/Cluster/Network/network-rx-above-5gb"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "node_network_rx_bytes"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Sum"
          threshold = 5000000000
          alarm_description = "EKS cluster network receive is above 5GB"
          treat_missing_data = "notBreaching"
          unit = "Bytes"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }
        network_tx = {
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "/${eks_config.short_name}" : ""}/Cluster/Network/network-tx-above-5gb"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "node_network_tx_bytes"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Sum"
          threshold = 5000000000
          alarm_description = "EKS cluster network transmit is above 5GB"
          treat_missing_data = "notBreaching"
          unit = "Bytes"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }
      } : "${eks_key}-${alarm_key}" => alarm_config
      if (length(try(eks_config.alarms, [])) == 0 || contains(try(eks_config.alarms, []), alarm_key)) && !contains(try(eks_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}

# Generate default dashboard widgets for EKS clusters
locals {
  eks_cluster_dashboard_widgets = [
    for eks_key, eks_config in local.all_eks_clusters : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["ContainerInsights", "node_cpu_utilization", "ClusterName", eks_config.name],
          [".", "node_memory_utilization", ".", "."],
          [".", "node_disk_utilization", ".", "."],
          [".", "node_network_rx_bytes", ".", "."],
          [".", "node_network_tx_bytes", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${eks_config.name} EKS Cluster Node Metrics"
      }
    }
  ]
}
