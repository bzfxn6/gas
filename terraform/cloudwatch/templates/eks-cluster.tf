# EKS Cluster Monitoring Template
# This template provides default monitoring for EKS clusters

# Default EKS cluster monitoring configuration
locals {
  eks_cluster_alarms = {
    cluster_cpu_utilization = {
      alarm_name          = "eks-cluster-cpu-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "node_cpu_utilization"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "EKS cluster CPU utilization is above 80%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
    cluster_memory_utilization = {
      alarm_name          = "eks-cluster-memory-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "node_memory_utilization"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "EKS cluster memory utilization is above 80%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
    cluster_disk_utilization = {
      alarm_name          = "eks-cluster-disk-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "node_filesystem_utilization"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Average"
      threshold           = 85
      alarm_description   = "EKS cluster disk utilization is above 85%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
    cluster_pod_count = {
      alarm_name          = "eks-cluster-pod-count"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "pod_number_of_running_containers"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Sum"
      threshold           = 100
      alarm_description   = "EKS cluster has more than 100 running pods"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    cluster_node_count = {
      alarm_name          = "eks-cluster-node-count"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 1
      metric_name         = "cluster_node_count"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Average"
      threshold           = 2
      alarm_description   = "EKS cluster has fewer than 2 nodes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    cluster_network_rx = {
      alarm_name          = "eks-cluster-network-rx"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "node_network_rx_bytes"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Sum"
      threshold           = 5000000000  # 5GB in bytes
      alarm_description   = "EKS cluster network receive is above 5GB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    cluster_network_tx = {
      alarm_name          = "eks-cluster-network-tx"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "node_network_tx_bytes"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Sum"
      threshold           = 5000000000  # 5GB in bytes
      alarm_description   = "EKS cluster network transmit is above 5GB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
  }
}

# Generate alarms for EKS clusters
locals {
  eks_cluster_monitoring = merge([
    for eks_key, eks_config in local.all_eks_clusters : {
      for alarm_key, alarm_config in local.eks_cluster_alarms : "${eks_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${eks_config.name}-${alarm_config.alarm_name}"
        dimensions = [
          {
            name  = "ClusterName"
            value = eks_config.name
          }
        ]
      })
      # Filter alarms based on user selection
      if length(eks_config.alarms) == 0 || contains(eks_config.alarms, alarm_key)
      # Exclude alarms if specified
      if !contains(coalesce(eks_config.exclude_alarms, []), alarm_key)
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
