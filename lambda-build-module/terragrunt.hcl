locals {
  # Basic configuration
  project = "test-project"
  environment = "dev"
  aws_region = "us-east-1"
  prefix = "${local.project}-${local.environment}"
  
  # S3 bucket for Lambda packages
  lambda_packages_bucket = "lambda-packages-${local.project}-${local.environment}"
  
  # Directory structure
  parent_directory = basename(get_terragrunt_dir())
  local_json_dir = format("%s/lambda-json", dirname(get_terragrunt_dir()))
  code_dir = format("%s/code", dirname(get_terragrunt_dir()))
}

terraform {
  source = "."
  
  before_hook "generate_hashes" {
    commands     = ["plan", "apply", "destroy"]
    execute      = ["./build-script.sh", local.code_dir, local.local_json_dir]
    run_on_error = false
  }
}

# Configure remote state backend
remote_state {
  backend = "s3"
  config = {
    bucket         = "terraform-state-gas-test-904233119504"
    key            = "${local.parent_directory}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-locks-gas-test"
  }
}

inputs = {
  # S3 bucket configuration
  lambda_packages_bucket = local.lambda_packages_bucket
  aws_region = local.aws_region
  
  # Lambda configurations
  lambdas = {
    for lambda in fileset(local.local_json_dir, "*.json") :
    trimsuffix(lambda, ".json") => merge(
      jsondecode(templatefile("${local.local_json_dir}/${lambda}", {
        PROJECT = local.project
        ENVIRONMENT = local.environment
        PREFIX = local.prefix
        AWS_REGION = local.aws_region
        LAMBDA_PATH = dirname(get_terragrunt_dir())
        TAGS = jsonencode({
          Project = local.project
          Environment = local.environment
          Component = "lambda"
          ManagedBy = "terragrunt"
        })
      })),
      {
        # Add build-specific configuration
        source_file = "${local.code_dir}/${trimsuffix(lambda, ".json")}.py"
        package_key = "packages/${trimsuffix(lambda, ".json")}.zip"
        hash_file = "${get_terragrunt_dir()}/lambda_hashes.json"
      }
    )
  }
} 