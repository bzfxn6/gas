# EKS Pods Monitoring Locals
# This file contains all EKS pods/apps-related alarm definitions

locals {
  # Generate EKS pods alarms with dynamic naming
  eks_pod_alarms = merge([
    for pod_key, pod_config in local.all_eks_pods : {
      for alarm_key, alarm_config in {
        cpu_utilization = {
          alarm_name = "Sev2/${coalesce(try(pod_config.customer, null), var.customer)}/${coalesce(try(pod_config.team, null), var.team)}/EKS/Pods/CPU/cpu-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "pod_cpu_utilization"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "EKS pod CPU utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          severity = "Sev2"
          sub_service = "CPU"
          error_details = "cpu-utilization-above-80pct"
        }
        memory_utilization = {
          alarm_name = "Sev2/${coalesce(try(pod_config.customer, null), var.customer)}/${coalesce(try(pod_config.team, null), var.team)}/EKS/Pods/Memory/memory-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "pod_memory_utilization"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "EKS pod memory utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          severity = "Sev2"
          sub_service = "Memory"
          error_details = "memory-utilization-above-80pct"
        }
        restart_count = {
          alarm_name = "Sev2/${coalesce(try(pod_config.customer, null), var.customer)}/${coalesce(try(pod_config.team, null), var.team)}/EKS/Pods/Restarts/restart-count-above-5"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "pod_number_of_container_restarts"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Sum"
          threshold = 5
          alarm_description = "EKS pod has more than 5 container restarts"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "Restarts"
          error_details = "restart-count-above-5"
        }
        network_receive = {
          alarm_name = "Sev2/${coalesce(try(pod_config.customer, null), var.customer)}/${coalesce(try(pod_config.team, null), var.team)}/EKS/Pods/NetworkRX/network-receive-above-1gb"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "pod_network_rx_bytes"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Sum"
          threshold = 1073741824
          alarm_description = "EKS pod network receive is above 1GB"
          treat_missing_data = "notBreaching"
          unit = "Bytes"
          severity = "Sev2"
          sub_service = "NetworkRX"
          error_details = "network-receive-above-1gb"
        }
        network_transmit = {
          alarm_name = "Sev2/${coalesce(try(pod_config.customer, null), var.customer)}/${coalesce(try(pod_config.team, null), var.team)}/EKS/Pods/NetworkTX/network-transmit-above-1gb"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "pod_network_tx_bytes"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Sum"
          threshold = 1073741824
          alarm_description = "EKS pod network transmit is above 1GB"
          treat_missing_data = "notBreaching"
          unit = "Bytes"
          severity = "Sev2"
          sub_service = "NetworkTX"
          error_details = "network-transmit-above-1gb"
        }
      } : "${pod_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "PodName"
          value = pod_config.name
        }, {
          name = "Namespace"
          value = try(pod_config.namespace, "default")
        }, {
          name = "ClusterName"
          value = try(pod_config.cluster_name, "default")
        }]
      })
    }
  ]...)
}
