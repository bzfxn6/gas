# EKS Node Group Monitoring Template
# This template provides default monitoring for EKS node groups

# Convert single items to maps for consistent processing
locals {
  # Convert single EKS node group to map format
  single_eks_nodegroup_map = var.default_monitoring.eks_nodegroup != null ? {
    "single-eks-nodegroup" = var.default_monitoring.eks_nodegroup
  } : {}
  
  # Merge single items with maps
  all_eks_nodegroups = merge(local.single_eks_nodegroup_map, var.default_monitoring.eks_nodegroups)
}

# Default EKS node group monitoring configuration
locals {
  eks_nodegroup_alarms = {
    # Node Group Health and Status
    nodegroup_health = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "nodegroup_health"
      namespace           = "AWS/EKS"
      period              = 300
      statistic           = "Average"
      threshold           = 0
      alarm_description   = "EKS node group health check failed"
      treat_missing_data = "breaching"
      unit                = "Count"
      severity            = "high"
      sub_service         = "Health"
      error_details       = "nodegroup-health-check-failed"
    }
    
    # Node Count Monitoring
    node_count = {
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "node_count"
      namespace           = "AWS/EKS"
      period              = 300
      statistic           = "Average"
      threshold           = 1
      alarm_description   = "EKS node group has fewer than 1 node"
      treat_missing_data = "notBreaching"
      unit                = "Count"
      severity            = "high"
      sub_service         = "Nodes"
      error_details       = "node-count-below-1"
    }
    
    # Node Group Scaling
    scaling_activity = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "scaling_activity"
      namespace           = "AWS/EKS"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EKS node group scaling activity detected"
      treat_missing_data = "notBreaching"
      unit                = "Count"
      severity            = "medium"
      sub_service         = "Scaling"
      error_details       = "scaling-activity-detected"
    }
    
    # Node Group Capacity
    capacity_utilization = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "capacity_utilization"
      namespace           = "AWS/EKS"
      period              = 300
      statistic           = "Average"
      threshold           = 85
      alarm_description   = "EKS node group capacity utilization above 85%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
      severity            = "medium"
      sub_service         = "Capacity"
      error_details       = "capacity-utilization-above-85%"
    }
    
    # Node Group Instance Health
    instance_health = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "instance_health"
      namespace           = "AWS/EKS"
      period              = 300
      statistic           = "Average"
      threshold           = 0
      alarm_description   = "EKS node group has unhealthy instances"
      treat_missing_data = "breaching"
      unit                = "Count"
      severity            = "high"
      sub_service         = "Instances"
      error_details       = "unhealthy-instances-detected"
    }
    
    # Node Group Launch Template Version
    launch_template_version = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "launch_template_version"
      namespace           = "AWS/EKS"
      period              = 300
      statistic           = "Average"
      threshold           = 1
      alarm_description   = "EKS node group launch template version mismatch"
      treat_missing_data = "notBreaching"
      unit                = "Count"
      severity            = "low"
      sub_service         = "LaunchTemplate"
      error_details       = "launch-template-version-mismatch"
    }
    
    # Node Group Update Status
    update_status = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "update_status"
      namespace           = "AWS/EKS"
      period              = 300
      statistic           = "Average"
      threshold           = 0
      alarm_description   = "EKS node group update failed or in progress"
      treat_missing_data = "breaching"
      unit                = "Count"
      severity            = "medium"
      sub_service         = "Updates"
      error_details       = "update-status-failed-or-in-progress"
    }
    
    # Node Group Auto Scaling Group Health
    asg_health = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "asg_health"
      namespace           = "AWS/EKS"
      period              = 300
      statistic           = "Average"
      threshold           = 0
      alarm_description   = "EKS node group Auto Scaling Group health check failed"
      treat_missing_data = "breaching"
      unit                = "Count"
      severity            = "high"
      sub_service         = "AutoScaling"
      error_details       = "asg-health-check-failed"
    }
    
    # Node Group Spot Instance Interruption
    spot_interruption = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "spot_interruption"
      namespace           = "AWS/EKS"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EKS node group spot instance interruption detected"
      treat_missing_data = "notBreaching"
      unit                = "Count"
      severity            = "medium"
      sub_service         = "SpotInstances"
      error_details       = "spot-instance-interruption-detected"
    }
    
    # Node Group Instance Type Utilization
    instance_type_utilization = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "instance_type_utilization"
      namespace           = "AWS/EKS"
      period              = 300
      statistic           = "Average"
      threshold           = 90
      alarm_description   = "EKS node group instance type utilization above 90%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
      severity            = "medium"
      sub_service         = "InstanceType"
      error_details       = "instance-type-utilization-above-90%"
    }
    
    # EC2 Instance Status Check Failed
    status_check_failed = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "StatusCheckFailed"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 0
      alarm_description   = "EKS node group EC2 instance status check failed"
      treat_missing_data = "breaching"
      unit                = "Count"
      severity            = "high"
      sub_service         = "EC2Status"
      error_details       = "status-check-failed"
    }
    
    # EC2 Instance System Status Check Failed
    status_check_failed_system = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "StatusCheckFailed_System"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 0
      alarm_description   = "EKS node group EC2 instance system status check failed"
      treat_missing_data = "breaching"
      unit                = "Count"
      severity            = "high"
      sub_service         = "EC2SystemStatus"
      error_details       = "system-status-check-failed"
    }
    
    # EC2 Instance CPU Utilization
    cpu_utilization = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "EKS node group EC2 instance CPU utilization above 80%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
      severity            = "medium"
      sub_service         = "EC2CPU"
      error_details       = "cpu-utilization-above-80%"
    }
    
    # EBS IO Balance
    ebs_io_balance = {
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "EBSIOBalance%"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 20
      alarm_description   = "EKS node group EBS IO balance below 20%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
      severity            = "medium"
      sub_service         = "EBSIO"
      error_details       = "ebs-io-balance-below-20%"
    }
    
    # EBS Read Operations
    ebs_read_ops = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "EBSReadOps"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 200
      alarm_description   = "EKS node group EBS read operations above 200 per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
      severity            = "low"
      sub_service         = "EBSRead"
      error_details       = "ebs-read-ops-above-200"
    }
    
    # EBS Write Operations
    ebs_write_ops = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "EBSWriteOps"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 200
      alarm_description   = "EKS node group EBS write operations above 200 per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
      severity            = "low"
      sub_service         = "EBSWrite"
      error_details       = "ebs-write-ops-above-200"
    }
  }
}

# Generate alarms for EKS node groups
locals {
  eks_nodegroup_monitoring = merge([
    for nodegroup_key, nodegroup_config in local.all_eks_nodegroups : {
      for alarm_key, alarm_config in local.eks_nodegroup_alarms : "${nodegroup_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${alarm_config.severity}/${coalesce(nodegroup_config.customer, var.customer)}/${coalesce(nodegroup_config.team, var.team)}/EKS/NodeGroup/${alarm_config.sub_service}/${alarm_config.error_details}"
        dimensions = alarm_config.namespace == "AWS/EC2" ? [
          {
            name  = "AutoScalingGroupName"
            value = coalesce(nodegroup_config.asg_name, "eks-${nodegroup_config.cluster_name}-${nodegroup_config.name}")
          }
        ] : [
          {
            name  = "ClusterName"
            value = nodegroup_config.cluster_name
          },
          {
            name  = "NodegroupName"
            value = nodegroup_config.name
          }
        ]
      })
      # Filter alarms based on user selection
      if length(nodegroup_config.alarms) == 0 || contains(nodegroup_config.alarms, alarm_key)
      # Exclude alarms if specified
      if !contains(coalesce(nodegroup_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}

# Generate default dashboard widgets for EKS node groups
locals {
  eks_nodegroup_dashboard_widgets = [
    for nodegroup_key, nodegroup_config in local.all_eks_nodegroups : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/EKS", "node_count", "ClusterName", nodegroup_config.cluster_name, "NodegroupName", nodegroup_config.name],
          [".", "capacity_utilization", ".", ".", ".", "."],
          [".", "instance_health", ".", ".", ".", "."],
          [".", "scaling_activity", ".", ".", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${nodegroup_config.name} Node Group Metrics"
      }
    }
  ]
  
  eks_nodegroup_health_widgets = [
    for nodegroup_key, nodegroup_config in local.all_eks_nodegroups : {
      type   = "metric"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/EKS", "nodegroup_health", "ClusterName", nodegroup_config.cluster_name, "NodegroupName", nodegroup_config.name],
          [".", "update_status", ".", ".", ".", "."],
          [".", "asg_health", ".", ".", ".", "."],
          [".", "launch_template_version", ".", ".", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${nodegroup_config.name} Node Group Health"
      }
    }
  ]
  
  eks_nodegroup_scaling_widgets = [
    for nodegroup_key, nodegroup_config in local.all_eks_nodegroups : {
      type   = "metric"
      x      = 0
      y      = 6
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/EKS", "scaling_activity", "ClusterName", nodegroup_config.cluster_name, "NodegroupName", nodegroup_config.name],
          [".", "capacity_utilization", ".", ".", ".", "."],
          [".", "instance_type_utilization", ".", ".", ".", "."],
          [".", "spot_interruption", ".", ".", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${nodegroup_config.name} Node Group Scaling"
      }
    }
  ]
  
  eks_nodegroup_ec2_widgets = [
    for nodegroup_key, nodegroup_config in local.all_eks_nodegroups : {
      type   = "metric"
      x      = 12
      y      = 6
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", coalesce(nodegroup_config.asg_name, "eks-${nodegroup_config.cluster_name}-${nodegroup_config.name}")],
          [".", "StatusCheckFailed", ".", "."],
          [".", "StatusCheckFailed_System", ".", "."],
          [".", "EBSIOBalance%", ".", "."],
          [".", "EBSReadOps", ".", "."],
          [".", "EBSWriteOps", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${nodegroup_config.name} Node Group EC2 Metrics"
      }
    }
  ]
}
