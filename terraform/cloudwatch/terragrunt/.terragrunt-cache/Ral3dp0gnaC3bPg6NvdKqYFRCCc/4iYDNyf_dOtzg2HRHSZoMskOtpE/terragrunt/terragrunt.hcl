terraform {
  source = "../"
}

locals {
  local_dashboard_directory  = "${get_terragrunt_dir()}/dashboards"
  shared_dashboard_directory = "${get_terragrunt_dir()}/../../shared/dashboards"

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
          }
        }
      ]...)
    ]...)
  )

  region      = "us-east-1"
  environment = "dev"
  project     = "gas"
}

inputs = {
  dashboards  = local.dashboards
  region      = local.region
  environment = local.environment
  project     = local.project
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