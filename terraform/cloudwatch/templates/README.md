# CloudWatch Monitoring Templates

This directory contains modular templates for different types of AWS resource monitoring. Each template provides default alarms and dashboard widgets for specific resource types.

## Template Structure

### Base Template (`base.tf`)
Provides monitoring for common AWS resources:
- **Databases (RDS)**: CPU, memory, connections, read/write latency
- **Lambda Functions**: Errors, duration, throttles
- **SQS Queues**: Message age, queue depth, failed messages
- **ECS Services**: CPU, memory, running task count

### EKS Cluster Template (`eks-cluster.tf`)
Provides monitoring for EKS clusters:
- **Cluster CPU Utilization**: Triggers when cluster CPU > 80%
- **Cluster Memory Utilization**: Triggers when cluster memory > 80%
- **Cluster Disk Utilization**: Triggers when cluster disk > 85%
- **Cluster Pod Count**: Triggers when cluster has > 100 running pods
- **Cluster Node Count**: Triggers when cluster has < 2 nodes
- **Cluster Network**: Monitors network receive/transmit

### EKS Pods Template (`eks-pods.tf`)
Provides monitoring for individual EKS pods/applications:
- **Pod CPU Utilization Alarm**: Triggers when pod CPU > 80%
- **Pod Memory Utilization Alarm**: Triggers when pod memory > 80%
- **Pod Restart Count Alarm**: Triggers when pod has > 5 container restarts
- **Pod Network**: Monitors network receive/transmit
- **Pod Container Count**: Triggers when pod has no running containers
- **Pod Ready Status**: Triggers when pod is not ready

### EKS Node Groups Template (`eks-nodegroups.tf`)
Provides comprehensive monitoring for EKS node groups:
- **Node Group Health**: Monitors overall node group health status
- **Node Count**: Alerts when node count drops below minimum threshold
- **Scaling Activity**: Detects when node group is scaling up/down
- **Capacity Utilization**: Monitors node group capacity usage
- **Instance Health**: Alerts on unhealthy instances in the node group
- **Launch Template Version**: Detects version mismatches
- **Update Status**: Monitors node group update operations
- **Auto Scaling Group Health**: Monitors underlying ASG health
- **Spot Instance Interruption**: Detects spot instance interruptions
- **Instance Type Utilization**: Monitors specific instance type usage
- **EC2 Status Checks**: Monitors EC2 instance and system status checks
- **EC2 CPU Utilization**: Monitors EC2 instance CPU usage
- **EBS Operations**: Monitors EBS IO balance, read/write operations
- **Comprehensive Dashboards**: Multiple widget types for node group metrics including EC2 metrics

### Step Functions Template (`step-functions.tf`)
Provides comprehensive monitoring for AWS Step Functions:
- **Execution Monitoring**: Success rate, failures, throttling, time, aborts, timeouts
- **Activity Monitoring**: Success rate, failures, scheduling, timing
- **Lambda Integration**: Success rate, failures, scheduling, timing
- **Service Integration**: Success rate, failures, scheduling, timing
- **Comprehensive Dashboards**: Multiple widget types for different aspects of Step Functions

### EC2 Instances Template (`ec2.tf`)
Provides comprehensive monitoring for AWS EC2 instances:
- **CPU Monitoring**: Utilization, credit balance, credit usage
- **Network Monitoring**: Input/output bytes and packets
- **Disk Monitoring**: Read/write bytes and operations
- **Status Monitoring**: Instance and system status checks
- **EBS Monitoring**: Read/write bytes, operations, and balance
- **Comprehensive Dashboards**: Multiple widget types for different EC2 metrics

### S3 Buckets Template (`s3.tf`)
Provides comprehensive monitoring for AWS S3 buckets:
- **Capacity Monitoring**: Bucket size and object count
- **Request Monitoring**: All HTTP methods (GET, PUT, DELETE, etc.)
- **Performance Monitoring**: Latency and throughput metrics
- **Error Monitoring**: 4xx and 5xx error rates
- **Replication Monitoring**: Latency and pending operations
- **Multipart Upload Monitoring**: Count, parts, and bytes
- **Comprehensive Dashboards**: Multiple widget types for different S3 metrics

### EventBridge Template (`eventbridge.tf`)
Provides comprehensive monitoring for AWS EventBridge rules:
- **Rule Performance**: Triggered rules, invocations, failures
- **Delivery Monitoring**: Delivery success/failure, duration, target errors
- **Event Flow**: Sent, received, and dropped events
- **Replay Monitoring**: Replay events, failures, and cancellations
- **Comprehensive Dashboards**: Multiple widget types for different EventBridge metrics

### Main Template (`main.tf`)
Combines all templates and provides final outputs:
- Merges all default alarms from all templates
- Combines all dashboard widgets
- Generates overview dashboard with alarm status

## Usage

### Include All Templates
```hcl
# In your main.tf
module "cloudwatch" {
  source = "./terraform/cloudwatch"
  
  default_monitoring = {
    databases = {
      app-db = { name = "app-production-db" }
    }
    eks_clusters = {
      main-cluster = { name = "main-eks-cluster" }
    }
    eks_pods = {
      web-app = {
        name = "web-app-pod"
        namespace = "web"
        cluster_name = "main-eks-cluster"
      }
    }
    eks_nodegroups = {
      main-nodegroup = {
        name = "main-nodegroup"
        cluster_name = "main-eks-cluster"
      }
    }
  }
}
```

### Use Only Specific Templates
You can modify the template files to include only the monitoring you need:

1. **Database Only**: Keep only `base.tf` and remove EKS templates
2. **EKS Clusters Only**: Keep only `eks-cluster.tf`
3. **EKS Pods Only**: Keep only `eks-pods.tf`
4. **Custom Combination**: Mix and match templates as needed

## Customization

### Adding New Resource Types
1. Create a new template file (e.g., `elasticache.tf`)
2. Define default alarms and dashboard widgets
3. Add the resource type to `variables.tf`
4. Include the new template in `main.tf`

### Modifying Default Thresholds
Edit the alarm configurations in the respective template files:
```hcl
# Example: Change CPU threshold from 80% to 70%
cpu_utilization = {
  alarm_name          = "eks-cluster-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 70  # Changed from 80
  # ... rest of configuration
}
```

### Adding Custom Metrics
Add new alarm types to the template files:
```hcl
# Example: Add custom metric alarm
custom_metric = {
  alarm_name          = "eks-cluster-custom-metric"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "your_custom_metric"
  namespace           = "CustomNamespace"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  # ... rest of configuration
}
```

## Template Dependencies

### Required Variables
All templates depend on these variables being defined in `variables.tf`:
- `var.default_monitoring` - Resource configurations
- `var.region` - AWS region for metrics
- `var.common_tags` - Common tags for resources

### Template Loading Order
The templates are loaded in this order:
1. `base.tf` - Common resources
2. `eks-cluster.tf` - EKS clusters
3. `eks-pods.tf` - EKS pods
4. `main.tf` - Combines all templates

## Benefits of Template System

1. **Modularity**: Use only the monitoring you need
2. **Maintainability**: Easy to update specific resource types
3. **Reusability**: Templates can be shared across projects
4. **Flexibility**: Mix and match monitoring types
5. **Consistency**: Standardized monitoring across resources

## Best Practices

1. **Keep Templates Focused**: Each template should handle one resource type
2. **Use Consistent Naming**: Follow the established naming conventions
3. **Document Customizations**: Add comments for any custom thresholds
4. **Test Changes**: Validate template changes before production use
5. **Version Control**: Track template changes in your version control system

## Troubleshooting

### Common Issues

1. **Missing Variables**: Ensure all required variables are defined
2. **Template Conflicts**: Check for duplicate alarm names across templates
3. **Metric Names**: Verify metric names match your AWS service
4. **Dimensions**: Ensure dimensions are correctly mapped to your resources

### Debugging

1. **Check Terraform Plan**: Review the plan output for any errors
2. **Validate Templates**: Use `terraform validate` to check syntax
3. **Review Logs**: Check CloudWatch logs for metric collection issues
4. **Test Alarms**: Manually trigger alarms to verify functionality
