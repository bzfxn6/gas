terraform {
  source = "../"
}

locals {
  local_dashboard_directory  = "${get_terragrunt_dir()}/dashboards"
  shared_dashboard_directory = "${get_terragrunt_dir()}/../../shared/dashboards"

  # Load dashboard configurations from JSON files
  dashboards = merge(
    merge([
      for dashboard_file in fileset(local.local_dashboard_directory, "*.json") :
      merge([
        {
          for dashboard_key, dashboard_config in jsondecode(templatefile("${local.local_dashboard_directory}/${dashboard_file}", {
            environment = local.environment
            region      = local.region
            project     = local.project
          })) :
          "${trimsuffix(dashboard_file, ".json")}-${dashboard_key}" => {
            name           = dashboard_config.name
            dashboard_body = jsonencode(dashboard_config.dashboard_body)
            type           = dashboard_config.type != null ? dashboard_config.type : "custom"
            tags           = dashboard_config.tags != null ? dashboard_config.tags : {}
            linked_dashboards = dashboard_config.linked_dashboards != null ? dashboard_config.linked_dashboards : []
          }
        }
      ]...)
    ]...),
    merge([
      for dashboard_file in fileset(local.shared_dashboard_directory, "*.json") :
      merge([
        {
          for dashboard_key, dashboard_config in jsondecode(templatefile("${local.shared_dashboard_directory}/${dashboard_file}", {
            environment = local.environment
            region      = local.region
            project     = local.project
          })) :
          "shared-${trimsuffix(dashboard_file, ".json")}-${dashboard_key}" => {
            name           = dashboard_config.name
            dashboard_body = jsonencode(dashboard_config.dashboard_body)
            type           = dashboard_config.type != null ? dashboard_config.type : "custom"
            tags           = dashboard_config.tags != null ? dashboard_config.tags : {}
            linked_dashboards = dashboard_config.linked_dashboards != null ? dashboard_config.linked_dashboards : []
          }
        }
      ]...)
    ]...)
  )

  # Default monitoring configuration
  default_monitoring = {
    # Add your databases here
    databases = {
      main-database = {
        name = "main-${local.environment}-database"
      }
      read-replica = {
        name = "read-replica-${local.environment}"
      }
      analytics-db = {
        name = "analytics-${local.environment}-db"
      }
    }
    
    # Add your Lambda functions here
    lambdas = {
      api-function = {
        name = "api-${local.environment}-function"
      }
      data-processor = {
        name = "data-processor-${local.environment}"
      }
    }
    
    # Add your SQS queues here
    sqs_queues = {
      events-queue = {
        name = "events-${local.environment}-queue"
      }
      notifications-queue = {
        name = "notifications-${local.environment}-queue"
      }
    }
    
    # Add your ECS services here
    ecs_services = {
      web-app = {
        name = "web-${local.environment}-app"
        cluster_name = "${local.environment}-cluster"
      }
      api-service = {
        name = "api-${local.environment}-service"
        cluster_name = "${local.environment}-cluster"
      }
    }
    
    # Add your EKS clusters here
    eks_clusters = {
      main-cluster = {
        name = "main-${local.environment}-eks-cluster"
        region = local.region
      }
      secondary-cluster = {
        name = "secondary-${local.environment}-eks-cluster"
        region = local.region
      }
    }
    
    # Add your EKS pods/apps here
    eks_pods = {
      web-app-pod = {
        name = "web-${local.environment}-app-pod"
        namespace = "web"
        cluster_name = "main-${local.environment}-eks-cluster"
        region = local.region
      }
      api-pod = {
        name = "api-${local.environment}-pod"
        namespace = "api"
        cluster_name = "main-${local.environment}-eks-cluster"
        region = local.region
      }
      database-pod = {
        name = "database-${local.environment}-pod"
        namespace = "database"
        cluster_name = "main-${local.environment}-eks-cluster"
        region = local.region
      }
    }
    
    # Add your Step Functions here
    step_functions = {
      main-workflow = {
        name = "main-${local.environment}-workflow"
        region = local.region
        # ARN will be auto-generated if not provided
      }
      data-pipeline = {
        name = "data-${local.environment}-pipeline"
        region = local.region
      }
      notification-service = {
        name = "notification-${local.environment}-service"
        region = local.region
      }
    }
    
    # Add your EC2 instances here
    ec2_instances = {
      web-server = {
        name = "web-${local.environment}-server"
        region = local.region
        # Instance ID will be auto-generated if not provided
      }
      database-server = {
        name = "database-${local.environment}-server"
        region = local.region
      }
      batch-processor = {
        name = "batch-${local.environment}-processor"
        region = local.region
      }
    }
    
    # Add your S3 buckets here
    s3_buckets = {
      application-data = {
        name = "application-${local.environment}-data"
        region = local.region
      }
      user-uploads = {
        name = "user-${local.environment}-uploads"
        region = local.region
      }
      backup-storage = {
        name = "backup-${local.environment}-storage"
        region = local.region
      }
    }
  }

  # Custom alarms configuration
  alarms = {
    # Add custom alarms here
    high-error-rate = {
      alarm_name          = "high-error-rate-${local.environment}"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ErrorRate"
      namespace           = "CustomMetrics"
      period              = 300
      statistic           = "Average"
      threshold           = 5.0
      alarm_description   = "Error rate is above 5% in ${local.environment}"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
      alarm_actions       = ["arn:aws:sns:${local.region}:${local.account_id}:alerts-topic"]
    }
  }

  # Log groups configuration
  log_groups = {
    app-logs = {
      name               = "/aws/lambda/app-${local.environment}-logs"
      retention_in_days  = 30
      tags = {
        Service = "application"
        LogType = "lambda"
      }
    }
    access-logs = {
      name               = "/aws/applicationloadbalancer/access-logs-${local.environment}"
      retention_in_days  = 90
      tags = {
        Service = "load-balancer"
        LogType = "access"
      }
    }
  }

  # Event rules configuration
  event_rules = {
    maintenance-window = {
      name                = "maintenance-window-${local.environment}"
      description         = "Scheduled maintenance window for ${local.environment}"
      schedule_expression = "cron(0 2 ? * SUN *)"  # Every Sunday at 2 AM
      is_enabled          = true
      tags = {
        Service = "maintenance"
        Type    = "scheduled"
      }
    }
  }

  # Dashboard linking configuration
  dashboard_links = {
    overview_dashboard = {
      name = "overview-${local.environment}"
      description = "Overview dashboard for ${local.environment} environment"
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
            markdown = "# ${title(local.environment)} Environment Overview\n\nThis dashboard provides a comprehensive view of all monitored resources in the ${local.environment} environment."
          }
        }
      ]
    }
    
    link_groups = {
      application = {
        name = "Application Monitoring - ${title(local.environment)}"
        dashboards = ["app-overview", "business-metrics"]
        description = "Dashboards for application and business metrics in ${local.environment}"
      }
      infrastructure = {
        name = "Infrastructure Monitoring - ${title(local.environment)}"
        dashboards = ["overview-${local.environment}"]
        description = "Infrastructure and alarm status dashboards for ${local.environment}"
      }
    }
  }

  region      = "us-east-1"
  environment = "dev"
  project     = "gas"
  account_id  = "123456789012"  # Replace with your actual AWS account ID
}

inputs = {
  # Common configuration
  region      = local.region
  environment = local.environment
  project     = local.project
  
  # Common tags
  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terragrunt"
    Owner       = "devops-team"
  }
  
  # Default monitoring (automatic alarms and metrics)
  default_monitoring = local.default_monitoring
  
  # Custom dashboards
  dashboards = local.dashboards
  
  # Custom alarms
  alarms = local.alarms
  
  # Log groups
  log_groups = local.log_groups
  
  # Event rules
  event_rules = local.event_rules
  
  # Dashboard linking
  dashboard_links = local.dashboard_links
}

# Optional: Configure AWS provider
# Uncomment and modify if you need specific AWS provider configuration
# generate "provider" {
#   path      = "provider.tf"
#   if_exists = "overwrite_terragrunt"
#   contents  = <<EOF
# provider "aws" {
#   region = "us-east-1"
#   # Add any other provider configuration here
# }
# EOF
# }

# Optional: Configure backend for state management
# Uncomment and modify if you want to use remote state
# remote_state {
#   backend = "s3"
#   config = {
#     bucket         = "your-terraform-state-bucket"
#     key            = "cloudwatch-dashboards/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"
#   }
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
# } 