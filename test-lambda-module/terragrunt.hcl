

locals {
  # Basic configuration for testing
  project = "test-project"
  environment = "dev"
  aws_region = "us-east-1"
  prefix = "${local.project}-${local.environment}"
  
  # Module configuration
  module_url = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda//wrappers"
  module_version = "v8.0.1"
  
  # Directory structure
  parent_directory = basename(get_terragrunt_dir())
  local_json_dir = format("%s/lambda-json", get_terragrunt_dir())
  global_json_dir = format("%s/_envcommon/resources/_global/lambda-json", dirname(find_in_parent_folders()))
}

terraform {
  source = "${local.module_url}?ref=${local.module_version}"

  before_hook "generate_hashes" {
  commands     = ["plan", "apply", "destroy"]
  execute      = ["bash", "-c", "cd ${get_terragrunt_dir()} && ./test-script.sh"]
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
  items = merge(
    {
      for lambda in fileset(local.local_json_dir, "*.json") :
      trimsuffix(lambda, ".json") => merge(
        jsondecode(templatefile("${local.local_json_dir}/${lambda}", {
          PROJECT = local.project
          ENVIRONMENT = local.environment
          PREFIX = local.prefix
          AWS_REGION = local.aws_region
          LAMBDA_PATH = get_terragrunt_dir()
          LAMBDA_ROLE = "arn:aws:iam::123456789012:role/test-lambda-role"
          TAGS = jsonencode({
            Project = local.project
            Environment = local.environment
            Component = "lambda"
            ManagedBy = "terragrunt"
          })
        })),
        {
          # Use the pre-generated hash
          source_code_hash = try(
            jsondecode(file("${get_terragrunt_dir()}/lambda_hashes.json"))[trimsuffix(lambda, ".json")],
            ""
          )
        }
      )
    },
    {
      for lambda in fileset(local.global_json_dir, "*.json") :
      trimsuffix(lambda, ".json") => merge(
        jsondecode(templatefile("${local.global_json_dir}/${lambda}", {
          PROJECT = local.project
          ENVIRONMENT = local.environment
          PREFIX = local.prefix
          AWS_REGION = local.aws_region
          LAMBDA_PATH = get_terragrunt_dir()
          LAMBDA_ROLE = "arn:aws:iam::123456789012:role/test-lambda-role"
          TAGS = jsonencode({
            Project = local.project
            Environment = local.environment
            Component = "lambda"
            ManagedBy = "terragrunt"
          })
        })),
        {
          # Use the pre-generated hash
          source_code_hash = try(
            jsondecode(file("${get_terragrunt_dir()}/lambda_hashes.json"))[trimsuffix(lambda, ".json")],
            ""
          )
        }
      )
    }
  )
} 