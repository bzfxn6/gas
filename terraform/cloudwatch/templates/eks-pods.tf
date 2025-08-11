# EKS Pods/Apps Monitoring Template
# This template provides default monitoring for EKS pods and applications

# Default EKS pods/apps monitoring configuration
locals {
  eks_pod_alarms = {
    pod_cpu_utilization = {
      alarm_name          = "eks-pod-cpu-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "pod_cpu_utilization"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "EKS pod CPU utilization is above 80%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
    pod_memory_utilization = {
      alarm_name          = "eks-pod-memory-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "pod_memory_utilization"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "EKS pod memory utilization is above 80%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
    pod_restart_count = {
      alarm_name          = "eks-pod-restart-count"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "pod_number_of_container_restarts"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Sum"
      threshold           = 5
      alarm_description   = "EKS pod has more than 5 container restarts"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    pod_network_rx = {
      alarm_name          = "eks-pod-network-rx"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "pod_network_rx_bytes"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000000000  # 1GB in bytes
      alarm_description   = "EKS pod network receive is above 1GB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    pod_network_tx = {
      alarm_name          = "eks-pod-network-tx"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "pod_network_tx_bytes"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000000000  # 1GB in bytes
      alarm_description   = "EKS pod network transmit is above 1GB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    pod_container_count = {
      alarm_name          = "eks-pod-container-count"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 1
      metric_name         = "pod_number_of_containers"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Average"
      threshold           = 1
      alarm_description   = "EKS pod has no running containers"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    pod_ready_status = {
      alarm_name          = "eks-pod-ready-status"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 1
      metric_name         = "pod_status_ready"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Average"
      threshold           = 1
      alarm_description   = "EKS pod is not ready"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
  }
}

# Generate alarms for EKS pods
locals {
  eks_pod_monitoring = merge([
    for eks_key, eks_config in local.all_eks_pods : {
      for alarm_key, alarm_config in local.eks_pod_alarms : "${eks_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${eks_config.name}-${alarm_config.alarm_name}"
        dimensions = [
          {
            name  = "PodName"
            value = eks_config.name
          },
          {
            name  = "Namespace"
            value = eks_config.namespace
          },
          {
            name  = "ClusterName"
            value = eks_config.cluster_name
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

# Generate default dashboard widgets for EKS pods
locals {
  eks_pod_dashboard_widgets = [
    for eks_key, eks_config in local.all_eks_pods : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["ContainerInsights", "pod_cpu_utilization", "PodName", eks_config.name, "Namespace", eks_config.namespace, "ClusterName", eks_config.cluster_name],
          [".", "pod_memory_utilization", ".", ".", ".", ".", ".", "."],
          [".", "pod_network_rx_bytes", ".", ".", ".", ".", ".", "."],
          [".", "pod_network_tx_bytes", ".", ".", ".", ".", ".", "."],
          [".", "pod_number_of_running_containers", ".", ".", ".", ".", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${eks_config.name} EKS Pod Metrics"
      }
    }
  ]
}
