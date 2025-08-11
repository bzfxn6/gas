# EC2 Monitoring Template
# This template provides default monitoring for AWS EC2 instances

# Default EC2 monitoring configuration
locals {
  ec2_alarms = {
    cpu_utilization = {
      alarm_name          = "ec2-cpu-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "EC2 instance CPU utilization is above 80%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
    cpu_credit_balance = {
      alarm_name          = "ec2-cpu-credit-balance"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUCreditBalance"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 10
      alarm_description   = "EC2 instance CPU credit balance is below 10"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    cpu_credit_usage = {
      alarm_name          = "ec2-cpu-credit-usage"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUCreditUsage"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 5
      alarm_description   = "EC2 instance CPU credit usage is above 5"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    network_in = {
      alarm_name          = "ec2-network-in"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "NetworkIn"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 100000000  # 100MB in bytes
      alarm_description   = "EC2 instance network input is above 100MB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    network_out = {
      alarm_name          = "ec2-network-out"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "NetworkOut"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 100000000  # 100MB in bytes
      alarm_description   = "EC2 instance network output is above 100MB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    network_packets_in = {
      alarm_name          = "ec2-network-packets-in"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "NetworkPacketsIn"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 1000
      alarm_description   = "EC2 instance network packets in is above 1000"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    network_packets_out = {
      alarm_name          = "ec2-network-packets-out"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "NetworkPacketsOut"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 1000
      alarm_description   = "EC2 instance network packets out is above 1000"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    disk_read_bytes = {
      alarm_name          = "ec2-disk-read-bytes"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "DiskReadBytes"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 50000000  # 50MB in bytes
      alarm_description   = "EC2 instance disk read is above 50MB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    disk_write_bytes = {
      alarm_name          = "ec2-disk-write-bytes"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "DiskWriteBytes"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 50000000  # 50MB in bytes
      alarm_description   = "EC2 instance disk write is above 50MB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    disk_read_ops = {
      alarm_name          = "ec2-disk-read-ops"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "DiskReadOps"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 100
      alarm_description   = "EC2 instance disk read operations is above 100"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    disk_write_ops = {
      alarm_name          = "ec2-disk-write-ops"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "DiskWriteOps"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 100
      alarm_description   = "EC2 instance disk write operations is above 100"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    status_check_failed = {
      alarm_name          = "ec2-status-check-failed"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "StatusCheckFailed"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EC2 instance status check has failed"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    status_check_failed_instance = {
      alarm_name          = "ec2-status-check-failed-instance"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "StatusCheckFailed_Instance"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EC2 instance status check has failed"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    status_check_failed_system = {
      alarm_name          = "ec2-status-check-failed-system"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "StatusCheckFailed_System"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EC2 system status check has failed"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    ebs_read_bytes = {
      alarm_name          = "ec2-ebs-read-bytes"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "EBSReadBytes"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 100000000  # 100MB in bytes
      alarm_description   = "EC2 instance EBS read is above 100MB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    ebs_write_bytes = {
      alarm_name          = "ec2-ebs-write-bytes"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "EBSWriteBytes"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 100000000  # 100MB in bytes
      alarm_description   = "EC2 instance EBS write is above 100MB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    ebs_read_ops = {
      alarm_name          = "ec2-ebs-read-ops"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "EBSReadOps"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 200
      alarm_description   = "EC2 instance EBS read operations is above 200"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    ebs_write_ops = {
      alarm_name          = "ec2-ebs-write-ops"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "EBSWriteOps"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 200
      alarm_description   = "EC2 instance EBS write operations is above 200"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    ebs_io_balance = {
      alarm_name          = "ec2-ebs-io-balance"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "EBSIOBalance%"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 20
      alarm_description   = "EC2 instance EBS IO balance is below 20%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
    ebs_byte_balance = {
      alarm_name          = "ec2-ebs-byte-balance"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "EBSByteBalance%"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 20
      alarm_description   = "EC2 instance EBS byte balance is below 20%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
  }
}

# Generate alarms for EC2 instances
locals {
  ec2_monitoring = merge([
    for ec2_key, ec2_config in local.all_ec2_instances : {
      for alarm_key, alarm_config in local.ec2_alarms : "${ec2_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${ec2_config.name}-${alarm_config.alarm_name}"
        dimensions = [
          {
            name  = "InstanceId"
            value = ec2_config.instance_id != null ? ec2_config.instance_id : ec2_config.name
          }
        ]
      })
      # Filter alarms based on user selection
      if length(ec2_config.alarms) == 0 || contains(ec2_config.alarms, alarm_key)
      # Exclude alarms if specified
      if !contains(coalesce(ec2_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}

# Generate default dashboard widgets for EC2 instances
locals {
  ec2_dashboard_widgets = [
    for ec2_key, ec2_config in local.all_ec2_instances : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/EC2", "CPUUtilization", "InstanceId", ec2_config.instance_id != null ? ec2_config.instance_id : ec2_config.name],
          [".", "NetworkIn", ".", "."],
          [".", "NetworkOut", ".", "."],
          [".", "DiskReadBytes", ".", "."],
          [".", "DiskWriteBytes", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${ec2_config.name} EC2 Instance Metrics"
      }
    }
  ]
}

# Generate EBS-specific dashboard widgets for EC2 instances
locals {
  ec2_ebs_widgets = [
    for ec2_key, ec2_config in local.all_ec2_instances : {
      type   = "metric"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/EC2", "EBSReadBytes", "InstanceId", ec2_config.instance_id != null ? ec2_config.instance_id : ec2_config.name],
          [".", "EBSWriteBytes", ".", "."],
          [".", "EBSReadOps", ".", "."],
          [".", "EBSWriteOps", ".", "."],
          [".", "EBSIOBalance%", ".", "."],
          [".", "EBSByteBalance%", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${ec2_config.name} EC2 EBS Metrics"
      }
    }
  ]
}

# Generate status check widgets for EC2 instances
locals {
  ec2_status_widgets = [
    for ec2_key, ec2_config in local.all_ec2_instances : {
      type   = "metric"
      x      = 0
      y      = 6
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/EC2", "StatusCheckFailed", "InstanceId", ec2_config.instance_id != null ? ec2_config.instance_id : ec2_config.name],
          [".", "StatusCheckFailed_Instance", ".", "."],
          [".", "StatusCheckFailed_System", ".", "."],
          [".", "CPUCreditBalance", ".", "."],
          [".", "CPUCreditUsage", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${ec2_config.name} EC2 Status & Credit Metrics"
      }
    }
  ]
}
