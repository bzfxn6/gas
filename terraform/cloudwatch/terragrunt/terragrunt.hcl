terraform {
  source = "../"
}

# Terragrunt configuration for CloudWatch monitoring
# This configuration reads monitoring settings from JSON files

locals {
  # Environment and region configuration - can be overridden by environment variables
  environment = get_env("ENVIRONMENT", "production")
  region     = get_env("AWS_REGION", "us-east-1")
  project    = get_env("PROJECT", "my-app")

  # Alarm naming convention variables - can be overridden by environment variables
  customer = get_env("CUSTOMER", "enbd-preprod")
  team     = get_env("TEAM", "DNA")

  # Resource naming prefix - used for environment-specific naming
  resource_prefix = get_env("RESOURCE_PREFIX", "")

  # Dashboard control - set to false for dev environments where you don't want dashboards
  create_dashboards = get_env("CREATE_DASHBOARDS", "true") == "true"
  
  # Configuration control - enable/disable specific service monitoring
  enable_database_monitoring = get_env("ENABLE_DATABASE_MONITORING", "true") == "true"
  enable_lambda_monitoring = get_env("ENABLE_LAMBDA_MONITORING", "true") == "true"
  enable_eks_monitoring = get_env("ENABLE_EKS_MONITORING", "true") == "true"
  enable_ecs_monitoring = get_env("ENABLE_ECS_MONITORING", "true") == "true"
  enable_ec2_monitoring = get_env("ENABLE_EC2_MONITORING", "true") == "true"
  enable_s3_monitoring = get_env("ENABLE_S3_MONITORING", "true") == "true"
  enable_sqs_monitoring = get_env("ENABLE_SQS_MONITORING", "true") == "true"
  enable_step_functions_monitoring = get_env("ENABLE_STEP_FUNCTIONS_MONITORING", "true") == "true"
  enable_eventbridge_monitoring = get_env("ENABLE_EVENTBRIDGE_MONITORING", "true") == "true"
  enable_log_monitoring = get_env("ENABLE_LOG_MONITORING", "true") == "true"

  # Severity mapping
  severity_levels = {
    high   = "Sev1"
    medium = "Sev2"
    low    = "Sev3"
    info   = "Sev4"
  }
    
  # Dashboard configuration - controlled by environment variable
  dashboards = local.create_dashboards ? {
    overview = {
      name = "${local.environment}-infrastructure-overview"
      dashboard_body = jsonencode({
        widgets = [
          {
            type   = "alarm"
            x      = 0
            y      = 0
            width  = 24
            height = 6
            properties = {
              title = "Infrastructure Alarm Status Overview"
              alarms = []  # Will be populated dynamically
            }
          }
        ]
      })
    }
  } : {}
}

# Example: If you have dependencies, you can define them here
# dependency "eks" {
#   config_path = "../eks-cluster"
# }

# Module inputs
inputs = {
  region = local.region
  environment = local.environment
  project = local.project
  
  # Clean, simple for loop pattern like your security group example
  default_monitoring = merge(
    { for config_file in fileset("${get_terragrunt_dir()}/configs/global", "*.json") :
      trimsuffix(config_file, ".json") => jsondecode(templatefile("${get_terragrunt_dir()}/configs/global/${config_file}", {
        CUSTOMER     = local.customer
        TEAM         = local.team
        ENVIRONMENT  = local.environment
        REGION       = local.region
        PROJECT      = local.project
        RESOURCE_PREFIX = local.resource_prefix
        DEFAULT_ALARM_ACTIONS = join(",", try(split(",", get_env("DEFAULT_ALARM_ACTIONS", "")), []))
        DEFAULT_OK_ACTIONS = join(",", try(split(",", get_env("DEFAULT_OK_ACTIONS", "")), []))
        DEFAULT_INSUFFICIENT_DATA_ACTIONS = join(",", try(split(",", get_env("DEFAULT_INSUFFICIENT_DATA_ACTIONS", "")), []))
      }))
    },
    { for config_file in fileset("${get_terragrunt_dir()}/configs/local", "*.json") :
      trimsuffix(config_file, ".json") => jsondecode(templatefile("${get_terragrunt_dir()}/configs/local/${config_file}", {
        CUSTOMER     = local.customer
        TEAM         = local.team
        ENVIRONMENT  = local.environment
        REGION       = local.region
        PROJECT      = local.project
        RESOURCE_PREFIX = local.resource_prefix
        DEFAULT_ALARM_ACTIONS = join(",", try(split(",", get_env("DEFAULT_ALARM_ACTIONS", "")), []))
        DEFAULT_OK_ACTIONS = join(",", try(split(",", get_env("DEFAULT_OK_ACTIONS", "")), []))
        DEFAULT_INSUFFICIENT_DATA_ACTIONS = join(",", try(split(",", get_env("DEFAULT_INSUFFICIENT_DATA_ACTIONS", "")), []))
      }))
    },
    { for config_file in fileset("${get_terragrunt_dir()}/configs/${local.environment}", "*.json") :
      trimsuffix(config_file, ".json") => jsondecode(templatefile("${get_terragrunt_dir()}/configs/${local.environment}/${config_file}", {
        CUSTOMER     = local.customer
        TEAM         = local.team
        ENVIRONMENT  = local.environment
        REGION       = local.region
        PROJECT      = local.project
        RESOURCE_PREFIX = local.resource_prefix
        DEFAULT_ALARM_ACTIONS = join(",", try(split(",", get_env("DEFAULT_ALARM_ACTIONS", "")), []))
        DEFAULT_OK_ACTIONS = join(",", try(split(",", get_env("DEFAULT_OK_ACTIONS", "")), []))
        DEFAULT_INSUFFICIENT_DATA_ACTIONS = join(",", try(split(",", get_env("DEFAULT_INSUFFICIENT_DATA_ACTIONS", "")), []))
      }))
    }
  )
  
  dashboards = local.dashboards
  
  # Pass alarm naming convention variables
  customer = local.customer
  team = local.team
  severity_levels = local.severity_levels
  
  # Default alarm actions - you can override these with environment variables
  default_alarm_actions = try(split(",", get_env("DEFAULT_ALARM_ACTIONS", "")), [])
  default_ok_actions = try(split(",", get_env("DEFAULT_OK_ACTIONS", "")), [])
  default_insufficient_data_actions = try(split(",", get_env("DEFAULT_INSUFFICIENT_DATA_ACTIONS", "")), [])
  
  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terragrunt"
    Customer    = local.customer
    Team        = local.team
  }
} 