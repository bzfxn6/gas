# Comprehensive CloudWatch Module Example
# This example demonstrates all the features of the CloudWatch module

module "cloudwatch_comprehensive" {
  source = "../"
  
  region      = "us-east-1"
  environment = "prod"
  project     = "gas"
  
  # Common tags for all resources
  common_tags = {
    Environment = "prod"
    Project     = "gas"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }
  
  # Default monitoring configurations
  default_monitoring = {
    # Database monitoring - just add names and get default alarms/metrics
    databases = {
      main-database = {
        name = "main-${local.environment}-database"
        # Custom alarms for this specific database
        custom_alarms = {
          strict-cpu-utilization = {
            alarm_name          = "main-database-strict-cpu-utilization"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1
            metric_name         = "CPUUtilization"
            namespace           = "AWS/RDS"
            period              = 300
            statistic           = "Average"
            threshold           = 70  # More strict than default 80%
            alarm_description   = "Main database CPU utilization is above 70%"
            dimensions = [
              {
                name  = "DBInstanceIdentifier"
                value = "main-${local.environment}-database"
              }
            ]
          }
        }
      }
      
      read-replica = {
        name = "read-replica-${local.environment}"
      }
      
      analytics-db = {
        name = "analytics-${local.environment}-db"
      }
    }
    
    # Lambda monitoring - just add names and get default alarms/metrics
    lambdas = {
      user-api = {
        name = "user-api-function"
        # Custom alarms for this specific Lambda
        custom_alarms = {
          high-duration = {
            alarm_name          = "user-api-high-duration"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1
            metric_name         = "Duration"
            namespace           = "AWS/Lambda"
            period              = 300
            statistic           = "Average"
            threshold           = 10000  # 10 seconds
            alarm_description   = "User API Lambda duration is above 10 seconds"
            dimensions = [
              {
                name  = "FunctionName"
                value = "user-api-function"
              }
            ]
          }
        }
      }
      data-processor = {
        name = "data-processor-function"
      }
    }
    
    # SQS monitoring - just add names and get default alarms/metrics
    sqs_queues = {
      user-events = {
        name = "user-events-queue"
        # Custom alarms for this specific queue
        custom_alarms = {
          high-message-age = {
            alarm_name          = "user-events-high-message-age"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1
            metric_name         = "ApproximateAgeOfOldestMessage"
            namespace           = "AWS/SQS"
            period              = 300
            statistic           = "Maximum"
            threshold           = 60  # 1 minute
            alarm_description   = "User events queue has messages older than 1 minute"
            dimensions = [
              {
                name  = "QueueName"
                value = "user-events-queue"
              }
            ]
          }
        }
      }
      notifications = {
        name = "notifications-queue"
      }
    }
    
    # ECS monitoring - just add names and get default alarms/metrics
    ecs_services = {
      web-app = {
        name = "web-application"
        cluster_name = "production-cluster"
        # Custom alarms for this specific ECS service
        custom_alarms = {
          low-memory = {
            alarm_name          = "web-app-low-memory"
            comparison_operator = "LessThanThreshold"
            evaluation_periods  = 1
            metric_name         = "MemoryUtilization"
            namespace           = "AWS/ECS"
            period              = 300
            statistic           = "Average"
            threshold           = 20  # 20% memory utilization
            alarm_description   = "Web app has less than 20% memory utilization"
            dimensions = [
              {
                name  = "ServiceName"
                value = "web-application"
              },
              {
                name  = "ClusterName"
                value = "production-cluster"
              }
            ]
          }
        }
      }
      api-service = {
        name = "api-service"
        cluster_name = "production-cluster"
      }
    }
    
    # EKS cluster monitoring - just add names and get default alarms/metrics
    eks_clusters = {
      production-cluster = {
        name = "production-eks-cluster"
        region = "us-east-1"
        # Custom alarms for this specific EKS cluster
        custom_alarms = {
          high-pod-density = {
            alarm_name          = "production-cluster-high-pod-density"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1
            metric_name         = "pod_number_of_running_containers"
            namespace           = "ContainerInsights"
            period              = 300
            statistic           = "Sum"
            threshold           = 200
            alarm_description   = "Production EKS cluster has more than 200 running pods"
            dimensions = [
              {
                name  = "ClusterName"
                value = "production-eks-cluster"
              }
            ]
          }
        }
      }
      staging-cluster = {
        name = "staging-eks-cluster"
        region = "us-east-1"
      }
    }
    
    # EKS pods/apps monitoring - just add names and get default alarms/metrics
    eks_pods = {
      web-frontend = {
        name = "web-frontend-pod"
        namespace = "web"
        cluster_name = "production-eks-cluster"
        region = "us-east-1"
        # Custom alarms for this specific EKS pod
        custom_alarms = {
          high-network-usage = {
            alarm_name          = "web-frontend-high-network-usage"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1
            metric_name         = "pod_network_rx_bytes"
            namespace           = "ContainerInsights"
            period              = 300
            statistic           = "Sum"
            threshold           = 5000000000  # 5GB in bytes
            alarm_description   = "Web frontend pod network receive is above 5GB"
            dimensions = [
              {
                name  = "PodName"
                value = "web-frontend-pod"
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
      api-backend = {
        name = "api-backend-pod"
        namespace = "api"
        cluster_name = "production-eks-cluster"
        region = "us-east-1"
      }
      database-proxy = {
        name = "database-proxy-pod"
        namespace = "database"
        cluster_name = "production-eks-cluster"
        region = "us-east-1"
      }
    }
    
    # EKS node groups monitoring - just add names and get default alarms/metrics
    eks_nodegroups = {
      production-main = {
        name = "production-main-nodegroup"
        cluster_name = "production-eks-cluster"
        asg_name = "eks-production-eks-cluster-production-main-nodegroup-20231201"
        region = "us-east-1"
        # Custom alarms for this specific node group
        custom_alarms = {
          strict-node-count = {
            alarm_name          = "production-main-strict-node-count"
            comparison_operator = "LessThanThreshold"
            evaluation_periods  = 1
            metric_name         = "node_count"
            namespace           = "AWS/EKS"
            period              = 300
            statistic           = "Average"
            threshold           = 3
            alarm_description   = "Production main node group has fewer than 3 nodes"
            dimensions = [
              {
                name  = "ClusterName"
                value = "production-eks-cluster"
              },
              {
                name  = "NodegroupName"
                value = "production-main-nodegroup"
              }
            ]
          }
        }
      }
      production-spot = {
        name = "production-spot-nodegroup"
        cluster_name = "production-eks-cluster"
        asg_name = "eks-production-eks-cluster-production-spot-nodegroup-20231201"
        region = "us-east-1"
        alarms = ["nodegroup_health", "node_count", "spot_interruption", "status_check_failed", "cpu_utilization"]
      }
      staging-main = {
        name = "staging-main-nodegroup"
        cluster_name = "staging-eks-cluster"
        asg_name = "eks-staging-eks-cluster-staging-main-nodegroup-20231201"
        region = "us-east-1"
      }
    }
    
    # Step Function monitoring - just add names and get default alarms/metrics
    step_functions = {
      order-processing = {
        name = "order-processing-workflow"
        arn = "arn:aws:states:us-east-1:123456789012:stateMachine:order-processing-workflow"
        region = "us-east-1"
        # Custom alarms for this specific Step Function
        custom_alarms = {
          strict-execution-time = {
            alarm_name          = "order-processing-strict-execution-time"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1
            metric_name         = "ExecutionTime"
            namespace           = "AWS/States"
            period              = 300
            statistic           = "Average"
            threshold           = 120000  # 2 minutes instead of default 5 minutes
            alarm_description   = "Order processing workflow execution time is above 2 minutes"
            dimensions = [
              {
                name  = "StateMachineArn"
                value = "arn:aws:states:us-east-1:123456789012:stateMachine:order-processing-workflow"
              }
            ]
          }
        }
      }
      
      data-pipeline = {
        name = "data-pipeline-workflow"
        arn = "arn:aws:states:us-east-1:123456789012:stateMachine:data-pipeline-workflow"
        region = "us-east-1"
      }
      
      notification-service = {
        name = "notification-service-workflow"
        region = "us-east-1"
        # No ARN provided, will be auto-generated
      }
    }
    
    # EC2 instance monitoring - just add names and get default alarms/metrics
    ec2_instances = {
      web-server = {
        name = "web-server-instance"
        instance_id = "i-1234567890abcdef0"
        region = "us-east-1"
        # Custom alarms for this specific EC2 instance
        custom_alarms = {
          strict-cpu-utilization = {
            alarm_name          = "web-server-strict-cpu-utilization"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1
            metric_name         = "CPUUtilization"
            namespace           = "AWS/EC2"
            period              = 300
            statistic           = "Average"
            threshold           = 70  # More strict than default 80%
            alarm_description   = "Web server CPU utilization is above 70%"
            dimensions = [
              {
                name  = "InstanceId"
                value = "i-1234567890abcdef0"
              }
            ]
          }
        }
      }
      
      database-server = {
        name = "database-server-instance"
        instance_id = "i-0987654321fedcba0"
        region = "us-east-1"
      }
      
      batch-processor = {
        name = "batch-processor-instance"
        region = "us-east-1"
        # No instance ID provided, will use name as dimension
      }
    }
    
    # S3 bucket monitoring - just add names and get default alarms/metrics
    s3_buckets = {
      application-data = {
        name = "application-data-bucket"
        region = "us-east-1"
        # Custom alarms for this specific S3 bucket
        custom_alarms = {
          strict-bucket-size = {
            alarm_name          = "application-data-strict-bucket-size"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1
            metric_name         = "BucketSizeBytes"
            namespace           = "AWS/S3"
            period              = 86400  # 24 hours for S3 metrics
            statistic           = "Average"
            threshold           = 500000000000  # 500GB instead of default 1TB
            alarm_description   = "Application data bucket size is above 500GB"
            dimensions = [
              {
                name  = "BucketName"
                value = "application-data-bucket"
              },
              {
                name  = "StorageType"
                value = "StandardStorage"
              }
            ]
          }
        }
      }
      
      user-uploads = {
        name = "user-uploads-bucket"
        region = "us-east-1"
      }
      
      backup-storage = {
        name = "backup-storage-bucket"
        region = "us-east-1"
      }
    }
    
    # EventBridge rule monitoring - just add names and get default alarms/metrics
    eventbridge_rules = {
      order-events = {
        name = "order-events-rule"
        region = "us-east-1"
        # Custom alarms for this specific EventBridge rule
        custom_alarms = {
          strict-failed-invocations = {
            alarm_name          = "order-events-strict-failed-invocations"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 1
            metric_name         = "FailedInvocations"
            namespace           = "AWS/Events"
            period              = 300
            statistic           = "Sum"
            threshold           = 0
            alarm_description   = "Order events rule has failed invocations"
            dimensions = [
              {
                name  = "RuleName"
                value = "order-events-rule"
              }
            ]
          }
        }
      }
      
      notification-events = {
        name = "notification-events-rule"
        region = "us-east-1"
      }
      
      data-processing = {
        name = "data-processing-rule"
        region = "us-east-1"
      }
    }
    
    # Log-based alarm monitoring
    log_alarms = {
      api-error-pattern = {
        log_group_name = "/aws/lambda/api-function"
        pattern = "[timestamp, level=ERROR, message]"
        transformation_name = "APIErrorCount"
        transformation_namespace = "CustomMetrics"
        transformation_value = "1"
        default_value = "0"
        alarm_description = "Error log pattern detected in API function logs"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods = 1
        period = 300
        statistic = "Sum"
        threshold = 0
        treat_missing_data = "notBreaching"
        unit = "Count"
        severity = "Sev1"
        sub_service = "Errors"
        error_details = "api-error-pattern-detected"
        customer = "enbd-preprod"
        team = "DNA"
        alarm_actions = ["arn:aws:sns:us-east-1:123456789012:alerts-topic"]
      }
      
      high-latency-pattern = {
        log_group_name = "/aws/lambda/api-function"
        pattern = "[timestamp, level=INFO, message=*latency*, duration=*]"
        transformation_name = "HighLatencyCount"
        transformation_namespace = "CustomMetrics"
        transformation_value = "1"
        default_value = "0"
        alarm_description = "High latency requests detected in API function logs"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods = 2
        period = 300
        statistic = "Sum"
        threshold = 5
        treat_missing_data = "notBreaching"
        unit = "Count"
        severity = "Sev2"
        sub_service = "Performance"
        error_details = "high-latency-requests-detected"
        customer = "enbd-preprod"
        team = "DNA"
      }
      
      auth-failures = {
        log_group_name = "/aws/applicationloadbalancer/access-logs"
        pattern = "[timestamp, client_ip, target_ip, request_processing_time, target_processing_time, response_processing_time, elb_status_code, target_status_code, received_bytes, sent_bytes, request, user_agent, ssl_cipher, ssl_protocol, target_group_arn, trace_id, domain_name, chosen_cert_arn, matched_rule_priority, request_creation_time, actions_executed, redirect_url, lambda_error_reason, target_port_list, target_status_code_list, classification, classification_reason]"
        transformation_name = "AuthFailureCount"
        transformation_namespace = "CustomMetrics"
        transformation_value = "1"
        default_value = "0"
        alarm_description = "Authentication failures detected in ALB access logs"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods = 1
        period = 300
        statistic = "Sum"
        threshold = 10
        treat_missing_data = "notBreaching"
        unit = "Count"
        severity = "Sev1"
        sub_service = "Security"
        error_details = "authentication-failures-detected"
        customer = "enbd-preprod"
        team = "DNA"
      }
    }
  }
  
  # Custom dashboards
  dashboards = {
    # Custom application dashboard
    app-overview = {
      name = "application-overview"
      type = "application"
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
                ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app-lb"],
                [".", "TargetResponseTime", ".", "."],
                [".", "HTTPCode_Target_5XX_Count", ".", "."]
              ]
              period = 300
              stat   = "Sum"
              region = "us-east-1"
              title  = "Application Load Balancer Metrics"
            }
          },
          {
            type   = "metric"
            x      = 12
            y      = 0
            width  = 12
            height = 6
            properties = {
              metrics = [
                ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "app-asg"],
                [".", "NetworkIn", ".", "."],
                [".", "NetworkOut", ".", "."]
              ]
              period = 300
              stat   = "Average"
              region = "us-east-1"
              title  = "EC2 Instance Metrics"
            }
          }
        ]
      })
      tags = {
        Service = "application"
        Tier    = "frontend"
      }
    }
    
    # Custom business metrics dashboard
    business-metrics = {
      name = "business-metrics"
      type = "business"
      dashboard_body = jsonencode({
        widgets = [
          {
            type   = "text"
            x      = 0
            y      = 0
            width  = 24
            height = 3
            properties = {
              markdown = "# Business Metrics Dashboard\n\nThis dashboard shows key business KPIs and metrics."
            }
          },
          {
            type   = "metric"
            x      = 0
            y      = 3
            width  = 12
            height = 6
            properties = {
              metrics = [
                ["CustomMetrics", "UserSignups", "Environment", "production"],
                [".", "ActiveUsers", ".", "."],
                [".", "Revenue", ".", "."]
              ]
              period = 3600
              stat   = "Sum"
              region = "us-east-1"
              title  = "User Metrics"
            }
          }
        ]
      })
      tags = {
        Service = "business-intelligence"
        Tier    = "analytics"
      }
    }
  }
  
  # Custom alarms (in addition to default ones)
  alarms = {
    # Custom business metric alarm
    high-error-rate = {
      alarm_name          = "high-error-rate"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ErrorRate"
      namespace           = "CustomMetrics"
      period              = 300
      statistic           = "Average"
      threshold           = 5.0
      alarm_description   = "Error rate is above 5%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
      alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:alerts-topic"]
      tags = {
        Service = "monitoring"
        Metric  = "error-rate"
      }
    }
    
    # Custom availability alarm
    low-availability = {
      alarm_name          = "low-availability"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 1
      metric_name         = "Availability"
      namespace           = "CustomMetrics"
      period              = 300
      statistic           = "Average"
      threshold           = 99.9
      alarm_description   = "Service availability is below 99.9%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
      alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:alerts-topic"]
      tags = {
        Service = "monitoring"
        Metric  = "availability"
      }
    }
  }
  
  # Log groups
  log_groups = {
    app-logs = {
      name               = "/aws/lambda/app-logs"
      retention_in_days  = 30
      tags = {
        Service = "application"
        LogType = "lambda"
      }
    }
    access-logs = {
      name               = "/aws/applicationloadbalancer/access-logs"
      retention_in_days  = 90
      tags = {
        Service = "load-balancer"
        LogType = "access"
      }
    }
  }
  
  # Event rules
  event_rules = {
    # Scheduled maintenance rule
    maintenance-window = {
      name                = "maintenance-window"
      description         = "Scheduled maintenance window for database updates"
      schedule_expression = "cron(0 2 ? * SUN *)"  # Every Sunday at 2 AM
      is_enabled          = true
      tags = {
        Service = "maintenance"
        Type    = "scheduled"
      }
    }
    
    # CloudTrail security events rule
    security-events = {
      name          = "security-events"
      description   = "Monitor security-related CloudTrail events"
      event_pattern = jsonencode({
        source      = ["aws.cloudtrail"]
        detail-type = ["AWS API Call via CloudTrail"]
        detail = {
          eventName = ["DeleteBucket", "DeleteUser", "DeleteRole", "DeletePolicy"]
        }
      })
      is_enabled = true
      tags = {
        Service = "security"
        Type    = "monitoring"
      }
    }
  }
  
  # Event targets
  event_targets = {
    # Target for maintenance window
    maintenance-lambda = {
      rule_key  = "maintenance-window"
      target_id = "maintenance-lambda"
      arn       = "arn:aws:lambda:us-east-1:123456789012:function:maintenance-handler"
      input     = jsonencode({
        action = "start-maintenance"
        services = ["database", "application"]
      })
    }
    
    # Target for security events
    security-sns = {
      rule_key  = "security-events"
      target_id = "security-sns"
      arn       = "arn:aws:sns:us-east-1:123456789012:security-alerts"
      input_transformer = {
        input_paths = {
          eventName = "$.detail.eventName"
          user      = "$.detail.userIdentity.arn"
          time      = "$.time"
        }
        input_template = jsonencode({
          message = "Security event detected: <eventName> by <user> at <time>"
        })
      }
    }
  }
  
  # Dashboard linking configuration
  dashboard_links = {
    # Overview dashboard that shows all alarms
    overview_dashboard = {
      name = "overview-dashboard"
      description = "Overview dashboard showing all CloudWatch alarms and key metrics"
      include_all_alarms = true
      include_all_metrics = true
      custom_widgets = [
        {
          type   = "text"
          x      = 0
          y      = 6
          width  = 24
          height = 3
          properties = {
            markdown = "## Resource Summary\n\nThis dashboard provides a comprehensive view of all monitored resources."
          }
        },
        {
          type   = "metric"
          x      = 0
          y      = 9
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/CloudWatch", "MetricCount", "Namespace", "AWS/RDS"],
              [".", ".", ".", "AWS/Lambda"],
              [".", ".", ".", "AWS/SQS"],
              [".", ".", ".", "AWS/ECS"]
            ]
            period = 300
            stat   = "Sum"
            region = "us-east-1"
            title  = "Metric Count by Service"
          }
        }
      ]
    }
    
    # Link groups for related dashboards
    link_groups = {
      application = {
        name = "Application Monitoring"
        dashboards = ["application-overview", "business-metrics"]
        description = "Dashboards for application and business metrics"
      }
      infrastructure = {
        name = "Infrastructure Monitoring"
        dashboards = ["overview-dashboard"]
        description = "Infrastructure and alarm status dashboards"
      }
    }
  }
}
