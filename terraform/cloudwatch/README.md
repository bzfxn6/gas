# Comprehensive CloudWatch Module

This Terraform module provides a comprehensive solution for CloudWatch monitoring, including dashboards, alarms, log groups, event rules, and event targets. It features automatic default monitoring for common AWS resources and the ability to create custom monitoring configurations.

## Features

- **Automatic Default Monitoring**: Pre-configured alarms and metrics for databases, Lambda functions, SQS queues, and ECS services
- **Custom Monitoring**: Full support for custom alarms, metrics, and dashboards
- **Dashboard Linking**: Create overview dashboards that link to specific resource dashboards
- **Comprehensive Resource Support**: CloudWatch dashboards, alarms, log groups, event rules, and targets
- **Flexible Configuration**: Use simple maps to configure complex monitoring setups
- **Tagging Support**: Comprehensive tagging for all resources
- **Terragrunt Compatible**: Designed to work seamlessly with Terragrunt

## Quick Start

### Basic Usage (Just Add Resource Names)

```hcl
module "cloudwatch" {
  source = "./terraform/cloudwatch"
  
  region      = "us-east-1"
  environment = "prod"
  project     = "gas"
  
  # Just add resource names and get default monitoring
  default_monitoring = {
    databases = {
      app-db = { name = "app-production-db" }
      analytics-db = { name = "analytics-db" }
    }
    
    lambdas = {
      api = { name = "api-function" }
      processor = { name = "data-processor" }
    }
    
    sqs_queues = {
      events = { name = "events-queue" }
    }
  }
}
```

This simple configuration will automatically create:
- 5 default alarms for each database (CPU, memory, connections, read/write latency)
- 3 default alarms for each Lambda (errors, duration, throttles)
- 3 default alarms for each SQS queue (message age, queue depth, failed messages)

### Advanced Usage with Custom Monitoring

```hcl
module "cloudwatch" {
  source = "./terraform/cloudwatch"
  
  region      = "us-east-1"
  environment = "prod"
  project     = "gas"
  
  # Default monitoring with custom overrides
  default_monitoring = {
    databases = {
      app-db = {
        name = "app-production-db"
        custom_alarms = {
          high-connections = {
            alarm_name          = "app-db-high-connections"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1
            metric_name         = "DatabaseConnections"
            namespace           = "AWS/RDS"
            period              = 300
            statistic           = "Average"
            threshold           = 100
            dimensions = [
              {
                name  = "DBInstanceIdentifier"
                value = "app-production-db"
              }
            ]
          }
        }
      }
    }
  }
  
  # Custom dashboards
  dashboards = {
    app-overview = {
      name = "application-overview"
      dashboard_body = jsonencode({
        widgets = [
          {
            type   = "metric"
            x      = 0
            y      = 0
            width  = 12
            height = 6
            properties = {
              metrics = [
                ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app-lb"]
              ]
              period = 300
              stat   = "Sum"
              region = "us-east-1"
              title  = "Application Load Balancer Metrics"
            }
          }
        ]
      })
    }
  }
  
  # Custom alarms
  alarms = {
    high-error-rate = {
      alarm_name          = "high-error-rate"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ErrorRate"
      namespace           = "CustomMetrics"
      period              = 300
      statistic           = "Average"
      threshold           = 5.0
      alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:alerts-topic"]
    }
  }
}
```

## Inputs

### Common Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | AWS region for CloudWatch resources | `string` | `"us-east-1"` | no |
| environment | Environment name for tagging | `string` | `"dev"` | no |
| project | Project name for tagging | `string` | `"gas"` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

### Default Monitoring

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| default_monitoring.databases | Map of databases to monitor with default alarms | `map(object)` | `{}` | no |
| default_monitoring.lambdas | Map of Lambda functions to monitor with default alarms | `map(object)` | `{}` | no |
| default_monitoring.sqs_queues | Map of SQS queues to monitor with default alarms | `map(object)` | `{}` | no |
| default_monitoring.ecs_services | Map of ECS services to monitor with default alarms | `map(object)` | `{}` | no |

### Custom Resources

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dashboards | Map of custom CloudWatch dashboards | `map(object)` | `{}` | no |
| alarms | Map of custom CloudWatch alarms | `map(object)` | `{}` | no |
| log_groups | Map of CloudWatch log groups | `map(object)` | `{}` | no |
| event_rules | Map of CloudWatch event rules | `map(object)` | `{}` | no |
| event_targets | Map of CloudWatch event targets | `map(object)` | `{}` | no |

### Dashboard Linking

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dashboard_links.overview_dashboard | Configuration for overview dashboard | `object` | `null` | no |
| dashboard_links.link_groups | Groups of related dashboards | `map(object)` | `{}` | no |

## Default Monitoring

The module provides comprehensive default monitoring for common AWS services. You can simply add resource names and get automatic alarms and dashboards, or customize which specific alarms you want.

### Selective Alarm Selection

You can choose which alarms to include or exclude for each resource:

```hcl
default_monitoring = {
  databases = {
    main-db = {
      name = "main-database"
      # Only include specific alarms
      alarms = ["cpu_utilization", "memory_utilization", "database_connections"]
      # Or exclude specific alarms
      # exclude_alarms = ["read_latency", "write_latency"]
    }
  }
  
  ec2_instances = {
    web-server = {
      name = "web-server"
      # Only monitor CPU and network, skip disk monitoring
      alarms = ["cpu_utilization", "network_in", "network_out", "status_check_failed"]
      exclude_alarms = ["disk_read_bytes", "disk_write_bytes"]
    }
  }
}
```

**Note**: 
- If `alarms` is empty or not specified, all alarms from the template are included
- If `alarms` is specified, only those alarms are included
- `exclude_alarms` always takes precedence over `alarms`
- You can use either single items or maps for each service type

### Single vs Multiple Resources

You can specify either single resources or multiple resources:

```hcl
# Single resource (simplified)
default_monitoring = {
  database = { name = "main-database" }
  lambda = { name = "api-function" }
  ec2_instance = { name = "web-server" }
}

# Multiple resources (map)
default_monitoring = {
  databases = {
    main-db = { name = "main-database" }
    replica = { name = "read-replica" }
  }
  lambdas = {
    api = { name = "api-function" }
    worker = { name = "worker-function" }
  }
}

# Mixed approach
default_monitoring = {
  database = { name = "main-database" }  # Single
  lambdas = {  # Multiple
    api = { name = "api-function" }
    worker = { name = "worker-function" }
  }
}
```

### Database Monitoring

When you add a database to `default_monitoring.databases`, the module automatically creates:

- **CPU Utilization Alarm**: Triggers when CPU > 80%
- **Memory Utilization Alarm**: Triggers when memory > 80%
- **Database Connections Alarm**: Triggers when connections > 80% of max
- **Storage Space Alarm**: Triggers when storage < 20% free
- **Read/Write IOPS Alarms**: Triggers when IOPS exceed thresholds
- **Network Throughput Alarms**: Triggers when network usage is high

**Note**: Only the database name is required. CloudWatch automatically collects metrics from the RDS instance without needing to know the engine type or instance class.

### Lambda Monitoring

When you add a Lambda function to `default_monitoring.lambdas`, the module automatically creates:

- **Errors Alarm**: Triggers when errors > 0
- **Duration Alarm**: Triggers when duration > 30 seconds
- **Throttles Alarm**: Triggers when throttles > 0

### SQS Monitoring

When you add an SQS queue to `default_monitoring.sqs_queues`, the module automatically creates:

- **Message Age Alarm**: Triggers when oldest message > 5 minutes
- **Queue Depth Alarm**: Triggers when queue depth > 1000 messages
- **Failed Messages Alarm**: Triggers when failed sends > 0

### ECS Monitoring

When you add an ECS service to `default_monitoring.ecs_services`, the module automatically creates:

- **CPU Utilization Alarm**: Triggers when CPU > 80%
- **Memory Utilization Alarm**: Triggers when memory > 80%
- **Running Tasks Alarm**: Triggers when running tasks < 1

### EKS Cluster Monitoring

When you add an EKS cluster to `default_monitoring.eks_clusters`, the module automatically creates:

- **Cluster CPU Utilization Alarm**: Triggers when cluster CPU > 80%
- **Cluster Memory Utilization Alarm**: Triggers when cluster memory > 80%
- **Cluster Disk Utilization Alarm**: Triggers when cluster disk > 85%
- **Cluster Pod Count Alarm**: Triggers when cluster has > 100 running pods
- **Cluster Node Count Alarm**: Triggers when cluster has < 2 nodes

### EKS Pod/App Monitoring

When you add an EKS pod/app to `default_monitoring.eks_pods`, the module automatically creates:

- **Pod CPU Utilization Alarm**: Triggers when pod CPU > 80%
- **Pod Memory Utilization Alarm**: Triggers when pod memory > 80%
- **Pod Restart Count Alarm**: Triggers when pod has > 5 container restarts
- **Pod Network Receive Alarm**: Triggers when pod network receive > 1GB
- **Pod Network Transmit Alarm**: Triggers when pod network transmit > 1GB

### EKS Node Group Monitoring

When you add an EKS node group to `default_monitoring.eks_nodegroups`, the module automatically creates:

- **Node Group Health Alarm**: Triggers when node group health check fails
- **Node Count Alarm**: Triggers when node count drops below 1
- **Scaling Activity Alarm**: Detects when node group is scaling up/down
- **Capacity Utilization Alarm**: Triggers when capacity utilization > 85%
- **Instance Health Alarm**: Triggers when node group has unhealthy instances
- **Launch Template Version Alarm**: Detects version mismatches
- **Update Status Alarm**: Monitors node group update operations
- **Auto Scaling Group Health Alarm**: Monitors underlying ASG health
- **Spot Instance Interruption Alarm**: Detects spot instance interruptions
- **Instance Type Utilization Alarm**: Triggers when instance type utilization > 90%
- **EC2 Status Check Failed Alarm**: Triggers when EC2 instance status check fails
- **EC2 System Status Check Failed Alarm**: Triggers when EC2 system status check fails
- **EC2 CPU Utilization Alarm**: Triggers when EC2 CPU > 80%
- **EBS IO Balance Alarm**: Triggers when EBS IO balance < 20%
- **EBS Read Operations Alarm**: Triggers when EBS read ops > 200 per 5 minutes
- **EBS Write Operations Alarm**: Triggers when EBS write ops > 200 per 5 minutes

### Step Function Monitoring

When you add a Step Function to `default_monitoring.step_functions`, the module automatically creates:

- **Execution Success Rate Alarm**: Triggers when success rate < 95%
- **Execution Failure Rate Alarm**: Triggers when failures > 0
- **Execution Throttled Alarm**: Triggers when executions are throttled
- **Execution Time Alarm**: Triggers when execution time > 5 minutes
- **Execution Aborted Alarm**: Triggers when executions are aborted
- **Execution Timed Out Alarm**: Triggers when executions time out
- **Activity Failed Alarm**: Triggers when activities fail
- **Activity Success Rate Alarm**: Triggers when activity success rate < 95%
- **Activity Time Alarm**: Triggers when activity time > 1 minute
- **Lambda Function Failed Alarm**: Triggers when Lambda functions fail
- **Lambda Function Success Rate Alarm**: Triggers when Lambda success rate < 95%
- **Lambda Function Time Alarm**: Triggers when Lambda time > 30 seconds
- **Service Integration Failed Alarm**: Triggers when service integrations fail
- **Service Integration Success Rate Alarm**: Triggers when service integration success rate < 95%
- **Service Integration Time Alarm**: Triggers when service integration time > 1 minute

### EC2 Instance Monitoring

When you add an EC2 instance to `default_monitoring.ec2_instances`, the module automatically creates:

- **CPU Utilization Alarm**: Triggers when CPU > 80%
- **CPU Credit Balance Alarm**: Triggers when CPU credit balance < 10
- **CPU Credit Usage Alarm**: Triggers when CPU credit usage > 5
- **Network Input Alarm**: Triggers when network input > 100MB
- **Network Output Alarm**: Triggers when network output > 100MB
- **Network Packets Input Alarm**: Triggers when network packets input > 1000
- **Network Packets Output Alarm**: Triggers when network packets output > 1000
- **Disk Read Bytes Alarm**: Triggers when disk read > 50MB
- **Disk Write Bytes Alarm**: Triggers when disk write > 50MB
- **Disk Read Operations Alarm**: Triggers when disk read operations > 100
- **Disk Write Operations Alarm**: Triggers when disk write operations > 100
- **Status Check Failed Alarm**: Triggers when status check fails
- **Status Check Failed Instance Alarm**: Triggers when instance status check fails
- **Status Check Failed System Alarm**: Triggers when system status check fails
- **EBS Read Bytes Alarm**: Triggers when EBS read > 100MB
- **EBS Write Bytes Alarm**: Triggers when EBS write > 100MB
- **EBS Read Operations Alarm**: Triggers when EBS read operations > 200
- **EBS Write Operations Alarm**: Triggers when EBS write operations > 200
- **EBS IO Balance Alarm**: Triggers when EBS IO balance < 20%
- **EBS Byte Balance Alarm**: Triggers when EBS byte balance < 20%

### S3 Bucket Monitoring

When you add an S3 bucket to `default_monitoring.s3_buckets`, the module automatically creates:

- **Bucket Size Bytes Alarm**: Triggers when bucket size > 1TB
- **Number of Objects Alarm**: Triggers when object count > 10 million
- **All Requests Alarm**: Triggers when requests > 10,000 per 5 minutes
- **GET Requests Alarm**: Triggers when GET requests > 8,000 per 5 minutes
- **PUT Requests Alarm**: Triggers when PUT requests > 2,000 per 5 minutes
- **DELETE Requests Alarm**: Triggers when DELETE requests > 100 per 5 minutes
- **HEAD Requests Alarm**: Triggers when HEAD requests > 5,000 per 5 minutes
- **POST Requests Alarm**: Triggers when POST requests > 1,000 per 5 minutes
- **LIST Requests Alarm**: Triggers when LIST requests > 3,000 per 5 minutes
- **Bytes Downloaded Alarm**: Triggers when downloads > 1GB per 5 minutes
- **Bytes Uploaded Alarm**: Triggers when uploads > 500MB per 5 minutes
- **First Byte Latency Alarm**: Triggers when first byte latency > 1 second
- **Total Request Latency Alarm**: Triggers when total request latency > 2 seconds
- **4xx Errors Alarm**: Triggers when 4xx errors > 100 per 5 minutes
- **5xx Errors Alarm**: Triggers when 5xx errors > 50 per 5 minutes
- **Replication Latency Alarm**: Triggers when replication latency > 5 minutes
- **Replication Bytes Pending Alarm**: Triggers when replication bytes pending > 1GB
- **Replication Operations Pending Alarm**: Triggers when replication operations pending > 1,000
- **Multipart Upload Count Alarm**: Triggers when multipart uploads > 100 per 5 minutes
- **Multipart Upload Parts Alarm**: Triggers when multipart upload parts > 1,000 per 5 minutes
- **Multipart Upload Bytes Alarm**: Triggers when multipart upload bytes > 1GB per 5 minutes

### EventBridge Monitoring

When you add an EventBridge rule to `default_monitoring.eventbridge_rules`, the module automatically creates:

- **Failed Invocations Alarm**: Triggers when invocations fail
- **Dead Letter Invocations Alarm**: Triggers when events go to dead letter queue
- **Throttled Rules Alarm**: Triggers when rules are throttled
- **Triggered Rules Alarm**: Triggers when > 1,000 rules triggered per 5 minutes
- **Invocations Alarm**: Triggers when > 1,000 invocations per 5 minutes
- **Delivery Failed Alarm**: Triggers when event delivery fails
- **Delivery Duration Alarm**: Triggers when delivery duration > 5 seconds
- **Target Errors Alarm**: Triggers when target errors occur
- **Target Duration Alarm**: Triggers when target duration > 30 seconds
- **Sent Events Alarm**: Triggers when > 1,000 events sent per 5 minutes
- **Received Events Alarm**: Triggers when > 1,000 events received per 5 minutes
- **Dropped Events Alarm**: Triggers when events are dropped
- **Replay Failed Alarm**: Triggers when replay fails
- **Replay Canceled Alarm**: Triggers when replay is canceled
- **Replay Events Alarm**: Triggers when > 100 replay events per 5 minutes

### Log-Based Alarm Monitoring

When you add a log-based alarm to `default_monitoring.log_alarms`, the module automatically creates:

- **CloudWatch Log Metric Filter**: Extracts metrics from log patterns
- **Custom Metric Alarm**: Monitors the extracted metric with your specified thresholds
- **Standardized Alarm Naming**: Follows the same naming convention as other alarms

**Required Configuration**:
- `log_group_name`: CloudWatch Log Group to monitor
- `pattern`: Log pattern to match (CloudWatch Logs filter pattern syntax)
- `transformation_name`: Name for the extracted metric
- `transformation_namespace`: Namespace for the extracted metric
- `transformation_value`: Value to extract from matched logs
- `alarm_description`: Description of the alarm
- `comparison_operator`: Alarm comparison operator
- `evaluation_periods`: Number of evaluation periods
- `period`: Evaluation period in seconds
- `statistic`: Statistical function to apply
- `threshold`: Alarm threshold value

**Example Log-Based Alarm**:
```hcl
log_alarms = {
  error-pattern = {
    log_group_name = "/aws/lambda/api-function"
    pattern = "[timestamp, level=ERROR, message]"
    transformation_name = "ErrorCount"
    transformation_namespace = "CustomMetrics"
    transformation_value = "1"
    alarm_description = "Error log pattern detected"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 1
    period = 300
    statistic = "Sum"
    threshold = 0
    severity = "Sev1"
    sub_service = "Errors"
    error_details = "error-log-pattern-detected"
  }
}
```

## Dashboard Linking

The module supports creating overview dashboards that link to specific resource dashboards:

```hcl
dashboard_links = {
  overview_dashboard = {
    name = "overview-dashboard"
    include_all_alarms = true
    include_all_metrics = true
    custom_widgets = [
      # Your custom widgets here
    ]
  }
  
  link_groups = {
    application = {
      name = "Application Monitoring"
      dashboards = ["app-overview", "business-metrics"]
      description = "Dashboards for application and business metrics"
    }
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| dashboard_names | Names of all created CloudWatch dashboards |
| dashboard_arns | ARNs of all created CloudWatch dashboards |
| alarm_names | Names of all created CloudWatch alarms |
| alarm_arns | ARNs of all created CloudWatch alarms |
| log_group_names | Names of all created CloudWatch log groups |
| event_rule_names | Names of all created CloudWatch event rules |
| total_resources | Count of all created resources by type |
| resource_summary | Detailed summary of all created resources |

## Examples

See the `example/` directory for complete working examples:

- `simple-usage.tf` - Basic usage with default monitoring
- `comprehensive-example.tf` - Full feature demonstration

## Supported AWS Services

This module supports monitoring for:

- **RDS Databases**: MySQL, PostgreSQL, Aurora, etc.
- **Lambda Functions**: All Lambda function types
- **SQS Queues**: Standard and FIFO queues
- **ECS Services**: Fargate and EC2 launch types
- **EKS Clusters**: Kubernetes clusters with Container Insights
- **EKS Pods/Apps**: Individual Kubernetes pods and applications
- **EKS Node Groups**: Kubernetes node groups with comprehensive scaling and health monitoring
- **Step Functions**: State machines with comprehensive workflow monitoring
- **EC2 Instances**: Virtual machines with comprehensive system monitoring
- **S3 Buckets**: Object storage with performance and capacity monitoring
- **EventBridge**: Event routing and processing with comprehensive rule monitoring
- **Log-Based Alarms**: CloudWatch Logs with metric filters and transformations
- **Custom Metrics**: Any CloudWatch metric
- **Log Groups**: CloudWatch Logs
- **Event Rules**: CloudWatch Events/EventBridge
- **Event Targets**: Lambda, SNS, SQS, ECS, etc.

## Best Practices

1. **Use Default Monitoring**: Start with default monitoring for common resources
2. **Customize When Needed**: Add custom alarms for specific business requirements
3. **Link Dashboards**: Create overview dashboards for operational visibility
4. **Tag Resources**: Use consistent tagging for resource management
5. **Monitor Costs**: Set appropriate retention periods for log groups
6. **Use SNS Topics**: Configure alarm actions for notifications

## Migration from Previous Version

If you're upgrading from the previous version:

1. The `dashboards` variable structure remains the same
2. New variables are optional and have sensible defaults
3. Existing configurations will continue to work
4. Add `default_monitoring` to get automatic monitoring for common resources

## Contributing

This module is designed to be extensible. To add support for new AWS services:

1. Add default alarm configurations to `locals.tf`
2. Update the `default_monitoring` variable type
3. Add resource generation logic in `locals.tf`
4. Update documentation and examples

## License

This module is part of the GAS project and follows the same licensing terms. 

## Threshold Customization

The CloudWatch module supports flexible threshold customization for different instances, environments, and resource types. You can override default thresholds while maintaining the convenience of automatic monitoring.

### Method 1: Instance-Specific Custom Alarms (Recommended)

Override default thresholds for specific instances while keeping defaults for others:

```hcl
module "cloudwatch" {
  source = "./terraform/cloudwatch"
  
  default_monitoring = {
    eks_clusters = {
      # Production cluster with custom thresholds
      production-cluster = {
        name = "production-eks-cluster"
        custom_alarms = {
          # Override CPU threshold to be more strict for production
          cluster_cpu_utilization = {
            alarm_name          = "production-cluster-cpu-utilization"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 2
            metric_name         = "node_cpu_utilization"
            namespace           = "ContainerInsights"
            period              = 300
            statistic           = "Average"
            threshold           = 70  # More strict than default 80%
            alarm_description   = "Production cluster CPU utilization is above 70%"
            dimensions = [
              {
                name  = "DBInstanceIdentifier"
                value = "production-eks-cluster"
              }
            ]
          }
          # Override memory threshold for production
          cluster_memory_utilization = {
            alarm_name          = "production-cluster-memory-utilization"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 2
            metric_name         = "node_memory_utilization"
            namespace           = "ContainerInsights"
            period              = 300
            statistic           = "Average"
            threshold           = 75  # More strict than default 80%
            alarm_description   = "Production cluster memory utilization is above 75%"
            dimensions = [
              {
                name  = "DBInstanceIdentifier"
                value = "production-eks-cluster"
              }
            ]
          }
        }
      }
      
      # Staging cluster uses default thresholds
      staging-cluster = {
        name = "staging-eks-cluster"
      }
      
      # Development cluster with relaxed thresholds
      dev-cluster = {
        name = "dev-eks-cluster"
        custom_alarms = {
          cluster_cpu_utilization = {
            alarm_name          = "dev-cluster-cpu-utilization"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 2
            metric_name         = "node_cpu_utilization"
            namespace           = "ContainerInsights"
            period              = 300
            statistic           = "Average"
            threshold           = 90  # More relaxed than default 80%
            alarm_description   = "Dev cluster CPU utilization is above 90%"
            dimensions = [
              {
                name  = "DBInstanceIdentifier"
                value = "dev-eks-cluster"
              }
            ]
          }
        }
      }
    }
    
    eks_pods = {
      # Production web app with strict thresholds
      production-web-app = {
        name = "production-web-app-pod"
        namespace = "web"
        cluster_name = "production-eks-cluster"
        custom_alarms = {
          pod_cpu_utilization = {
            alarm_name          = "production-web-app-cpu-utilization"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1  # More sensitive
            metric_name         = "pod_cpu_utilization"
            namespace           = "ContainerInsights"
            period              = 300
            statistic           = "Average"
            threshold           = 60  # More strict than default 80%
            alarm_description   = "Production web app CPU utilization is above 60%"
            dimensions = [
              {
                name  = "PodName"
                value = "production-web-app-pod"
              },
              {
                name  = "Namespace"
                value = "web"
              },
              {
                name  = "ClusterName"
                value = "production-eks-cluster"
              }
            ]
          }
        }
      }
      
      # Background worker with relaxed thresholds
      background-worker = {
        name = "background-worker-pod"
        namespace = "workers"
        cluster_name = "production-eks-cluster"
        custom_alarms = {
          pod_cpu_utilization = {
            alarm_name          = "background-worker-cpu-utilization"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 3  # Less sensitive
            metric_name         = "pod_cpu_utilization"
            namespace           = "ContainerInsights"
            period              = 300
            statistic           = "Average"
            threshold           = 95  # More relaxed than default 80%
            alarm_description   = "Background worker CPU utilization is above 95%"
            dimensions = [
              {
                name  = "PodName"
                value = "background-worker-pod"
              },
              {
                name  = "Namespace"
                value = "workers"
              },
              {
                name  = "ClusterName"
                value = "production-eks-cluster"
              }
            ]
          }
        }
      }
    }
  }
}
```

### Method 2: Environment-Based Thresholds

Create different threshold profiles based on environment:

```hcl
locals {
  # Define threshold profiles for different environments
  threshold_profiles = {
    production = {
      cpu_utilization    = 70
      memory_utilization = 75
      disk_utilization   = 80
      evaluation_periods = 1
    }
    staging = {
      cpu_utilization    = 80
      memory_utilization = 80
      disk_utilization   = 85
      evaluation_periods = 2
    }
    development = {
      cpu_utilization    = 90
      memory_utilization = 90
      disk_utilization   = 95
      evaluation_periods = 3
    }
  }
  
  environment = "production"
  current_profile = local.threshold_profiles[local.environment]
}

module "cloudwatch" {
  source = "./terraform/cloudwatch"
  
  default_monitoring = {
    eks_clusters = {
      main-cluster = {
        name = "main-eks-cluster"
        custom_alarms = {
          cluster_cpu_utilization = {
            alarm_name          = "main-cluster-cpu-utilization"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = local.current_profile.evaluation_periods
            metric_name         = "node_cpu_utilization"
            namespace           = "ContainerInsights"
            period              = 300
            statistic           = "Average"
            threshold           = local.current_profile.cpu_utilization
            alarm_description   = "Main cluster CPU utilization is above ${local.current_profile.cpu_utilization}%"
            dimensions = [
              {
                name  = "ClusterName"
                value = "main-eks-cluster"
              }
            ]
          }
        }
      }
    }
  }
}
```

### Method 3: Resource Type-Based Thresholds

Different resource types can have different default thresholds:

```hcl
module "cloudwatch" {
  source = "./terraform/cloudwatch"
  
  default_monitoring = {
    eks_clusters = {
      # High-performance cluster with strict thresholds
      high-perf-cluster = {
        name = "high-perf-eks-cluster"
        custom_alarms = {
          cluster_cpu_utilization = {
            threshold = 60  # Strict for high-performance workloads
          }
          cluster_memory_utilization = {
            threshold = 70  # Strict for high-performance workloads
          }
        }
      }
      
      # Batch processing cluster with relaxed thresholds
      batch-cluster = {
        name = "batch-eks-cluster"
        custom_alarms = {
          cluster_cpu_utilization = {
            threshold = 95  # Relaxed for batch workloads
          }
          cluster_memory_utilization = {
            threshold = 95  # Relaxed for batch workloads
          }
        }
      }
    }
    
    eks_pods = {
      # Critical application with very strict thresholds
      critical-app = {
        name = "critical-app-pod"
        namespace = "critical"
        cluster_name = "high-perf-eks-cluster"
        custom_alarms = {
          pod_cpu_utilization = {
            threshold = 50  # Very strict for critical apps
            evaluation_periods = 1
          }
          pod_memory_utilization = {
            threshold = 60  # Very strict for critical apps
            evaluation_periods = 1
          }
        }
      }
      
      # Background service with relaxed thresholds
      background-service = {
        name = "background-service-pod"
        namespace = "background"
        cluster_name = "batch-eks-cluster"
        custom_alarms = {
          pod_cpu_utilization = {
            threshold = 95  # Very relaxed for background services
            evaluation_periods = 5
          }
        }
      }
    }
  }
}
```

### Method 4: Dynamic Thresholds Based on Instance Size

Set thresholds based on instance characteristics:

```hcl
locals {
  # Define thresholds based on instance size
  instance_thresholds = {
    small = {
      cpu_utilization    = 70
      memory_utilization = 75
      pod_count          = 50
    }
    medium = {
      cpu_utilization    = 80
      memory_utilization = 80
      pod_count          = 100
    }
    large = {
      cpu_utilization    = 85
      memory_utilization = 85
      pod_count          = 200
    }
  }
}

module "cloudwatch" {
  source = "./terraform/cloudwatch"
  
  default_monitoring = {
    eks_clusters = {
      small-cluster = {
        name = "small-eks-cluster"
        custom_alarms = {
          cluster_cpu_utilization = {
            threshold = local.instance_thresholds.small.cpu_utilization
          }
          cluster_pod_count = {
            threshold = local.instance_thresholds.small.pod_count
          }
        }
      }
      
      large-cluster = {
        name = "large-eks-cluster"
        custom_alarms = {
          cluster_cpu_utilization = {
            threshold = local.instance_thresholds.large.cpu_utilization
          }
          cluster_pod_count = {
            threshold = local.instance_thresholds.large.pod_count
          }
        }
      }
    }
  }
}
```

### Method 5: Database-Specific Thresholds

Customize thresholds for different database types and workloads:

```hcl
module "cloudwatch" {
  source = "./terraform/cloudwatch"
  
  default_monitoring = {
    databases = {
      # Production database with strict thresholds
      production-db = {
        name = "production-database"
        engine = "mysql"
        custom_alarms = {
          cpu_utilization = {
            threshold = 70  # More strict than default 80%
            evaluation_periods = 1
          }
          database_connections = {
            threshold = 60  # More strict than default 80
            evaluation_periods = 1
          }
          read_latency = {
            threshold = 0.5  # More strict than default 1 second
            evaluation_periods = 1
          }
        }
      }
      
      # Analytics database with relaxed thresholds
      analytics-db = {
        name = "analytics-database"
        engine = "postgres"
        custom_alarms = {
          cpu_utilization = {
            threshold = 95  # More relaxed for analytics workloads
            evaluation_periods = 3
          }
          database_connections = {
            threshold = 120  # Higher connection limit for analytics
            evaluation_periods = 2
          }
        }
      }
      
      # Development database with very relaxed thresholds
      dev-db = {
        name = "development-database"
        engine = "mysql"
        custom_alarms = {
          cpu_utilization = {
            threshold = 98  # Very relaxed for development
            evaluation_periods = 5
          }
          freeable_memory = {
            threshold = 100000000  # 100MB instead of 1GB
            evaluation_periods = 3
          }
        }
      }
    }
  }
}
```

### Method 6: Lambda Function-Specific Thresholds

Customize thresholds based on function criticality and expected behavior:

```hcl
module "cloudwatch" {
  source = "./terraform/cloudwatch"
  
  default_monitoring = {
    lambdas = {
      # Critical API function with strict thresholds
      critical-api = {
        name = "critical-api-function"
        custom_alarms = {
          errors = {
            threshold = 0  # No errors allowed for critical functions
            evaluation_periods = 1
          }
          duration = {
            threshold = 5000  # 5 seconds instead of 30
            evaluation_periods = 1
          }
          throttles = {
            threshold = 0  # No throttling allowed
            evaluation_periods = 1
          }
        }
      }
      
      # Background processor with relaxed thresholds
      background-processor = {
        name = "background-processor-function"
        custom_alarms = {
          errors = {
            threshold = 10  # Allow some errors for background processing
            evaluation_periods = 3
          }
          duration = {
            threshold = 60000  # 1 minute instead of 30 seconds
            evaluation_periods = 3
          }
          throttles = {
            threshold = 5  # Allow some throttling
            evaluation_periods = 2
          }
        }
      }
      
      # Batch job function with very relaxed thresholds
      batch-job = {
        name = "batch-job-function"
        custom_alarms = {
          duration = {
            threshold = 300000  # 5 minutes for batch jobs
            evaluation_periods = 5
          }
          throttles = {
            threshold = 20  # Allow significant throttling for batch jobs
            evaluation_periods = 5
          }
        }
      }
    }
  }
}
```

## Threshold Customization Best Practices

### 1. **Start with Defaults, Customize as Needed**
- Begin with default thresholds for all resources
- Gradually customize thresholds based on actual usage patterns
- Monitor and adjust thresholds based on performance data

### 2. **Environment-Based Thresholds**
- Use stricter thresholds for production environments
- Use relaxed thresholds for development and staging
- Consider business impact when setting thresholds

### 3. **Workload-Based Thresholds**
- Critical applications: Strict thresholds, immediate alerts
- Background services: Relaxed thresholds, longer evaluation periods
- Batch processing: Very relaxed thresholds, high tolerance

### 4. **Resource Capacity Considerations**
- Smaller instances: Lower thresholds due to limited capacity
- Larger instances: Higher thresholds due to greater capacity
- Auto-scaling groups: Consider scaling behavior when setting thresholds

### 5. **Business Hours vs. Off-Hours**
- Consider different thresholds for business hours vs. off-hours
- Use CloudWatch Events to adjust thresholds automatically
- Implement different notification strategies for different time periods

### 6. **Threshold Documentation**
- Document the reasoning behind custom thresholds
- Include business context and impact analysis
- Maintain threshold change logs for audit purposes

## Summary of Threshold Customization Options

1. **Instance-Specific**: Override thresholds for specific instances using `custom_alarms`
2. **Environment-Based**: Use different threshold profiles for different environments
3. **Resource Type-Based**: Set thresholds based on workload characteristics
4. **Instance Size-Based**: Adjust thresholds based on resource capacity
5. **Database-Specific**: Customize thresholds for different database types
6. **Lambda-Specific**: Adjust thresholds based on function criticality
7. **Hybrid Approach**: Combine multiple methods for maximum flexibility

The template system gives you complete control over thresholds while maintaining the convenience of defaults. You can start with default thresholds and gradually customize them for specific instances as needed! 