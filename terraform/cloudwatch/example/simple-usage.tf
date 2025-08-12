# Simple CloudWatch Module Usage Example
# This example shows basic usage with default monitoring

module "cloudwatch_simple" {
  source = "../"
  
  region      = "us-east-1"
  environment = "dev"
  project     = "gas"
  
  # Just add database names and get default monitoring
  default_monitoring = {
    # Database monitoring - just add names and get default monitoring
    databases = {
      main-db = {
        name = "main-database"
      }
    }
    
    lambdas = {
      api-function = {
        name = "api-function"
      }
      processor = {
        name = "data-processor"
      }
    }
    
    sqs_queues = {
      events = {
        name = "events-queue"
      }
    }
    
    # EKS cluster monitoring - just add names and get default monitoring
    eks_clusters = {
      main-cluster = {
        name = "main-eks-cluster"
      }
    }
    
    # EKS pods/apps monitoring - just add names and get default monitoring
    eks_pods = {
      app-pod = {
        name = "app-pod"
        namespace = "default"
        cluster_name = "main-eks-cluster"
      }
    }
    
    # EKS node groups monitoring - just add names and get default monitoring
    eks_nodegroups = {
      main-nodegroup = {
        name = "main-nodegroup"
        cluster_name = "main-eks-cluster"
      }
    }
    
    # Step Function monitoring - just add names and get default monitoring
    step_functions = {
      main-workflow = {
        name = "main-workflow"
        region = "us-east-1"
      }
    }
    
    # EC2 instance monitoring - just add names and get default monitoring
    ec2_instances = {
      main-server = {
        name = "main-server"
        region = "us-east-1"
      }
    }
    
    # S3 bucket monitoring - just add names and get default monitoring
    s3_buckets = {
      main-bucket = {
        name = "main-bucket"
        region = "us-east-1"
      }
    }
    
    # EventBridge rule monitoring - just add names and get default monitoring
    eventbridge_rules = {
      main-rule = {
        name = "main-rule"
        region = "us-east-1"
      }
    }
    
    # Log-based alarm monitoring
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
      }
    }
  }
  
  # Optional: Add a simple custom dashboard
  dashboards = {
    overview = {
      name = "dev-overview"
      type = "overview"
      dashboard_body = jsonencode({
        widgets = [
          {
            type   = "text"
            x      = 0
            y      = 0
            width  = 24
            height = 3
            properties = {
              markdown = "# Development Environment Overview\n\nThis dashboard shows the status of all monitored resources."
            }
          }
        ]
      })
    }
  }
  
  # Optional: Add custom alarms
  alarms = {
    high-cpu = {
      alarm_name          = "high-cpu-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 90
      alarm_description   = "EC2 CPU utilization is above 90%"
      dimensions = [
        {
          name  = "AutoScalingGroupName"
          value = "app-asg"
        }
      ]
    }
  }
}
