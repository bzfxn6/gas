terraform {
  source = "../"
}

# Terragrunt configuration for CloudWatch monitoring
# This configuration reads monitoring settings from JSON files

locals {
  environment = "production"
  region     = "us-east-1"
  project    = "my-app"
  
  # Alarm naming convention variables
  customer = "enbd-preprod"  # Default customer - can be overridden in JSON
  team     = "DNA"           # Default team - can be overridden in JSON
  
  # Severity mapping
  severity_levels = {
    high   = "Sev1"
    medium = "Sev2"
    low    = "Sev3"
    info   = "Sev4"
  }
  
  # Read monitoring configurations from JSON files
  databases_config = jsondecode(file("${get_terragrunt_dir()}/configs/databases.json"))
  lambdas_config = jsondecode(file("${get_terragrunt_dir()}/configs/lambdas.json"))
  sqs_queues_config = jsondecode(file("${get_terragrunt_dir()}/configs/sqs-queues.json"))
  ecs_services_config = jsondecode(file("${get_terragrunt_dir()}/configs/ecs-services.json"))
  eks_clusters_config = jsondecode(file("${get_terragrunt_dir()}/configs/eks-clusters.json"))
  eks_pods_config = jsondecode(file("${get_terragrunt_dir()}/configs/eks-pods.json"))
  eks_nodegroups_config = jsondecode(file("${get_terragrunt_dir()}/configs/eks-nodegroups.json"))
  step_functions_config = jsondecode(file("${get_terragrunt_dir()}/configs/step-functions.json"))
  ec2_instances_config = jsondecode(file("${get_terragrunt_dir()}/configs/ec2-instances.json"))
  s3_buckets_config = jsondecode(file("${get_terragrunt_dir()}/configs/s3-buckets.json"))
  eventbridge_rules_config = jsondecode(file("${get_terragrunt_dir()}/configs/eventbridge-rules.json"))
  log_alarms_config = jsondecode(file("${get_terragrunt_dir()}/configs/log-alarms.json"))
  
  # Merge configurations with environment variables and default values
  default_monitoring = {
    databases = merge(
      local.databases_config,
      { for k, v in local.databases_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    lambdas = merge(
      local.lambdas_config,
      { for k, v in local.lambdas_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    sqs_queues = merge(
      local.sqs_queues_config,
      { for k, v in local.sqs_queues_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    ecs_services = merge(
      local.ecs_services_config,
      { for k, v in local.ecs_services_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        cluster_name = "${v.cluster_name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    eks_clusters = merge(
      local.eks_clusters_config,
      { for k, v in local.eks_clusters_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    eks_pods = merge(
      local.eks_pods_config,
      { for k, v in local.eks_pods_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        cluster_name = "${v.cluster_name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    eks_nodegroups = merge(
      local.eks_nodegroups_config,
      { for k, v in local.eks_nodegroups_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        cluster_name = "${v.cluster_name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    step_functions = merge(
      local.step_functions_config,
      { for k, v in local.step_functions_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    ec2_instances = merge(
      local.ec2_instances_config,
      { for k, v in local.ec2_instances_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    s3_buckets = merge(
      local.s3_buckets_config,
      { for k, v in local.s3_buckets_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    eventbridge_rules = merge(
      local.eventbridge_rules_config,
      { for k, v in local.eventbridge_rules_config : k => merge(v, { 
        name = "${v.name}-${local.environment}",
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
    
    log_alarms = merge(
      local.log_alarms_config,
      { for k, v in local.log_alarms_config : k => merge(v, { 
        customer = coalesce(v.customer, local.customer),
        team = coalesce(v.team, local.team)
      }) }
    )
  }
  
  # Dashboard configuration
  dashboards = {
    overview = {
      dashboard_name = "${local.environment}-infrastructure-overview"
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
  }
}

# Call the CloudWatch module
module "cloudwatch" {
  source = "../../terraform/cloudwatch"
  
  region = local.region
  environment = local.environment
  project = local.project
  
  default_monitoring = local.default_monitoring
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