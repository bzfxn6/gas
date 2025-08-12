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

  # Configuration directories
  global_conf_directory = "${get_terragrunt_dir()}/configs/global"
  local_conf_directory  = "${get_terragrunt_dir()}/configs/local"

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
  
  # Read JSON files dynamically using fileset() and templatefile()
  default_monitoring = merge(
    # Base configuration - you can override these with dependencies
    {
      databases = {}
      lambdas = {}
      sqs_queues = {}
      ecs_services = {}
      eks_clusters = {}
      eks_pods = {}
      eks_nodegroups = {}
      step_functions = {}
      ec2_instances = {}
      s3_buckets = {}
      eventbridge_rules = {}
      log_alarms = {}
    },
    # Read global JSON files dynamically
    { for config_file in fileset(local.global_conf_directory, "*.json") :
      trimsuffix(config_file, ".json") => jsondecode(templatefile("${local.global_conf_directory}/${config_file}",
        {
          ENVIRONMENT     = local.environment
          CUSTOMER        = local.customer
          TEAM           = local.team
          RESOURCE_PREFIX = local.resource_prefix
          PROJECT        = local.project
          REGION         = local.region
        }
      ))
    },
    # Read local JSON files dynamically (takes precedence over global)
    { for config_file in fileset(local.local_conf_directory, "*.json") :
      trimsuffix(config_file, ".json") => jsondecode(templatefile("${local.local_conf_directory}/${config_file}",
        {
          ENVIRONMENT     = local.environment
          CUSTOMER        = local.customer
          TEAM           = local.team
          RESOURCE_PREFIX = local.resource_prefix
          PROJECT        = local.project
          REGION         = local.region
        }
      ))
    }
  )
  
  dashboards = local.dashboards
  
  # Pass alarm naming convention variables
  customer = local.customer
  team = local.team
  severity_levels = local.severity_levels
  
  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terragrunt"
    Customer    = local.customer
    Team        = local.team
  }
} 