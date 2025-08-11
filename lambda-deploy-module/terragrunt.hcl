locals {
  # Basic configuration
  project = "test-project"
  environment = "dev"
  aws_region = "us-east-1"
  prefix = "${local.project}-${local.environment}"
  
  # S3 bucket for Lambda packages (from build module)
  lambda_packages_bucket = "lambda-packages-${local.project}-${local.environment}"
  
  # Directory structure
  parent_directory = basename(get_terragrunt_dir())
  local_json_dir = format("%s/lambda-json", dirname(get_terragrunt_dir()))
}

terraform {
  source = "."
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

# Get build module outputs
dependency "build" {
  config_path = "../lambda-build-module"
  
  mock_outputs = {
    lambda_packages_bucket = "mock-bucket"
    lambda_packages = {
      "test-lambda" = {
        bucket = "mock-bucket"
        key    = "packages/test-lambda.zip"
        etag   = "mock-etag"
        url    = "s3://mock-bucket/packages/test-lambda.zip"
      }
    }
    lambda_hashes = {
      "test-lambda" = "mock-hash"
    }
  }
}

inputs = {
  # S3 bucket configuration from build module
  lambda_packages_bucket = dependency.build.outputs.lambda_packages_bucket
  aws_region = local.aws_region
  
  # Lambda configurations for deployment
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
        # Add deployment-specific configuration
        s3_bucket = dependency.build.outputs.lambda_packages_bucket
        s3_key = dependency.build.outputs.lambda_packages[trimsuffix(lambda, ".json")].key
        source_code_hash = dependency.build.outputs.lambda_hashes[trimsuffix(lambda, ".json")]
      }
    )
  }
} 