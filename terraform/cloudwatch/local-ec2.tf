# EC2 Instances Monitoring Locals
# This file contains all EC2 instances-related alarm definitions

locals {
  # Generate EC2 instances alarms with dynamic naming
  ec2_alarms = merge([
    for ec2_key, ec2_config in local.all_ec2_instances : {
      for alarm_key, alarm_config in {
        cpu_utilization = {
          alarm_name = "Sev2/${coalesce(try(ec2_config.customer, null), var.customer)}/${coalesce(try(ec2_config.team, null), var.team)}/EC2/CPU/cpu-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "CPUUtilization"
          namespace = "AWS/EC2"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "EC2 instance CPU utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          severity = "Sev2"
          sub_service = "CPU"
          error_details = "cpu-utilization-above-80pct"
        }
        memory_utilization = {
          alarm_name = "Sev2/${coalesce(try(ec2_config.customer, null), var.customer)}/${coalesce(try(ec2_config.team, null), var.team)}/EC2/Memory/memory-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "MemoryUtilization"
          namespace = "AWS/EC2"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "EC2 instance memory utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          severity = "Sev2"
          sub_service = "Memory"
          error_details = "memory-utilization-above-80pct"
        }
        disk_utilization = {
          alarm_name = "Sev2/${coalesce(try(ec2_config.customer, null), var.customer)}/${coalesce(try(ec2_config.team, null), var.team)}/EC2/Disk/disk-utilization-above-85pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "DiskUtilization"
          namespace = "AWS/EC2"
          period = 300
          statistic = "Average"
          threshold = 85
          alarm_description = "EC2 instance disk utilization is above 85%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          severity = "Sev2"
          sub_service = "Disk"
          error_details = "disk-utilization-above-85pct"
        }
        network_in = {
          alarm_name = "Sev2/${coalesce(try(ec2_config.customer, null), var.customer)}/${coalesce(try(ec2_config.team, null), var.team)}/EC2/NetworkIN/network-in-above-1gb"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "NetworkIn"
          namespace = "AWS/EC2"
          period = 300
          statistic = "Average"
          threshold = 1073741824
          alarm_description = "EC2 instance network in is above 1GB"
          treat_missing_data = "notBreaching"
          unit = "Bytes"
          severity = "Sev2"
          sub_service = "NetworkIN"
          error_details = "network-in-above-1gb"
        }
        network_out = {
          alarm_name = "Sev2/${coalesce(try(ec2_config.customer, null), var.customer)}/${coalesce(try(ec2_config.team, null), var.team)}/EC2/NetworkOUT/network-out-above-1gb"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "NetworkOut"
          namespace = "AWS/EC2"
          period = 300
          statistic = "Average"
          threshold = 1073741824
          alarm_description = "EC2 instance network out is above 1GB"
          treat_missing_data = "notBreaching"
          unit = "Bytes"
          severity = "Sev2"
          sub_service = "NetworkOUT"
          error_details = "network-out-above-1gb"
        }
        status_check_failed = {
          alarm_name = "Sev1/${coalesce(try(ec2_config.customer, null), var.customer)}/${coalesce(try(ec2_config.team, null), var.team)}/EC2/StatusCheck/status-check-failed"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "StatusCheckFailed"
          namespace = "AWS/EC2"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "EC2 instance status check failed"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "StatusCheck"
          error_details = "status-check-failed"
        }
      } : "${ec2_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "InstanceId"
          value = ec2_config.name
        }]
      })
    }
  ]...)
}
