
Stepfunction.hcl
 
locals {
  global_vars           = try(read_terragrunt_config(find_in_parent_folders("global.hcl")), {})
  owner_vars            = try(read_terragrunt_config(find_in_parent_folders("owner.hcl")), {})
  account_vars          = try(read_terragrunt_config(find_in_parent_folders("account.hcl")), {})
  region_vars           = try(read_terragrunt_config(find_in_parent_folders("region.hcl")), {})
  environment_vars      = try(read_terragrunt_config(find_in_parent_folders("env.hcl")), {})
  modules_vars          = try(read_terragrunt_config(find_in_parent_folders("modules.hcl")), {})
  modules_versions_vars = try(read_terragrunt_config(find_in_parent_folders("version.hcl")), {})
  global_cidr           = try(read_terragrunt_config(find_in_parent_folders("global-cidr.hcl")), {})
  local_cidr            = try(read_terragrunt_config(find_in_parent_folders("local-cidr.hcl")), {})
 
  # set variables from shared files for easy of use.
  # owner vars
  project = local.owner_vars.locals.project
  # account vars
  aws_account_number = local.account_vars.locals.aws_account_number
  environment        = local.account_vars.locals.environment
  gss_account        = local.account_vars.locals.gss_account
 
  # region vars
  aws_region = local.region_vars.locals.aws_region
 
  # Global useful variables
 
  # module config
  module_url     = local.modules_vars.locals.module_urls.step_function_ext
  module_version = local.modules_versions_vars.locals.module_versions.step_function_ext
 
  # Useful variables for this module
  parent_directory = basename(get_terragrunt_dir())
  local_json_dir   = format("%s/%s-json", get_terragrunt_dir(), local.parent_directory)
  prefix           = "${local.project}-${local.environment}"
 
  service_directory = basename(dirname(dirname(get_terragrunt_dir())))
  global_json_dir   = strcontains(local.local_json_dir, "-vpc") ? format("%s/_envcommon/resources/%s/%s/step-function/%s-json", dirname(find_in_parent_folders()), local.environment_vars.locals.vpc_name, local.service_directory, local.parent_directory) : format("%s/_envcommon/resources/_global/%s-json", dirname(find_in_parent_folders()), local.parent_directory)
  # since we are only looking for 1 json file need to check if it is loacal or remote.
  json_dir_to_use = fileexists("${local.local_json_dir}/step-function-definition.json") ? local.local_json_dir : local.global_json_dir
}
 
terraform {
  source = "${local.module_url}?ref=${local.module_version}"
  #source = "../../../../../../../modules/gss-tuning-rds-aurora"
}
 
dependency "state_file_outputs" {
  config_path                             = format("%s/%s/%s/data", dirname(find_in_parent_folders()), local.project, local.environment)
  mock_outputs_allowed_terraform_commands = ["validate", "show", "plan", "init"]
  mock_outputs_merge_strategy_with_state  = "deep_map_only"
  mock_outputs = {
    map_output = {
      base = {
        vpc_id = "vpc-1234567890123456"
        alarm_actions = [
          "arn:aws:sns:eu-west-2:590184098826:gss-mock-base-metric-alarm",
        ]
        kms_admin_arn          = "arn:aws:kms:eu-west-2:123456789012:key/1111111-c4222229b-4333331f6-122-1111111"
        iam_terraform_role_arn = "arn:aws:kms:eu-west-2:123456789012:key/1111111-c4222229b-4333331f6-122-1111111"
        rds_subnet_group_id    = "base-db-subnet-group"
        db_subnet_group_id     = "db-subnet-group"
        kms_key_rds_arns = {
          default = "arn:aws:kms:eu-west-2:${local.aws_account_number}:key/12345678-1234-1234-1234-1234567890123"
        }
      }
    }
  }
}
 
dependency "lambda" {
  config_path                             = format("%s/%s/%s/%s/%s/app/lambda", dirname(find_in_parent_folders()), local.project, local.environment, local.aws_region, local.environment_vars.locals.vpc_name)
  mock_outputs_allowed_terraform_commands = ["validate", "show", "plan", "init"]
  mock_outputs_merge_strategy_with_state  = "deep_map_only"
  mock_outputs = {
    wrapper = {
      scm-batch-processor-send-to-sqs-core = {
        lambda_function_arn = "arn:aws:lambda:eu-west-2:123456789012:function:gss-mock-scm-batch-processor-send-to-sqs-core"
      }
      scm-batch-processor-send-to-kafka = {
        lambda_function_arn = "arn:aws:lambda:eu-west-2:123456789012:function:gss-mock-scm-batch-processor-send-to-kafka"
      }
      scm-batch-processor-read-s3 = {
        lambda_function_arn = "arn:aws:lambda:eu-west-2:123456789012:function:gss-mock-scm-batch-processor-read-s3"
      }
      scm-batch-processor-update-records = {
        lambda_function_arn = "arn:aws:lambda:eu-west-2:123456789012:function:gss-mock-scm-batch-processor-update-records"
      }
    }
  }
}
 
dependency "sqs_queue" {
  #config_path                             = format("%s/%s/%s/%s/%s/app/sqs", dirname(find_in_parent_folders()), local.project, local.environment, local.aws_region, local.environment_vars.locals.vpc_name)
  #config_path                             = "${get_original_terragrunt_dir()}/../sqs"
  config_path                             = format("%s/%s/%s/%s/%s/app/sqs", dirname(find_in_parent_folders()), local.project, local.environment, local.aws_region, local.environment_vars.locals.vpc_name)
  mock_outputs_allowed_terraform_commands = ["validate", "show", "plan", "init"]
  mock_outputs = {
    queue_url = {
      scm-batch-processor = "https://sqs.eu-west-2.amazonaws.com:123456789012:gss-mock-scm-batch-processor"
    }
  }
}
 
dependency "iam_roles" {
  config_path                             = format("%s/%s/%s/%s/%s/app/iam-roles", dirname(find_in_parent_folders()), local.project, local.environment, local.aws_region, local.environment_vars.locals.vpc_name)
  mock_outputs_allowed_terraform_commands = ["validate", "show", "plan", "init"]
  mock_outputs_merge_strategy_with_state  = "deep_map_only"
  mock_outputs = {
    role_arn = {
      "scm-batch-processor-step-function" = "arn:aws:iam::123456789012:role/gss-mock-scm-batch-processor-step-function-role"
    }
  }
}
 
inputs = {
  name              = "${local.prefix}-${local.parent_directory}"
  use_existing_role = true
  role_arn          = dependency.iam_roles.outputs.role_arn["scm-batch-processor-step-function"]
 
  definition = templatefile("${local.json_dir_to_use}/step-function-definition.json",
    {
      SCM_BATCH_PROC_SQS_CORE_LAMBDA_ARN       = dependency.lambda.outputs.wrapper["scm-batch-processor-send-to-sqs-core"].lambda_function_arn
      SCM_BATCH_PROC_SEND_TO_KAFKA_LAMBDA_ARN  = dependency.lambda.outputs.wrapper["scm-batch-processor-send-to-kafka"].lambda_function_arn
      SCM_BATCH_PROC_READ_S3_LAMBDA_ARN        = dependency.lambda.outputs.wrapper["scm-batch-processor-read-s3"].lambda_function_arn
      SCM_BATCH_PROC_UPDATE_RECORDS_LAMBDA_ARN = dependency.lambda.outputs.wrapper["scm-batch-processor-update-records"].lambda_function_arn
      SCM_BATCH_PROC_SQS_QUEUE_URL             = dependency.sqs_queue.outputs["queue_url"].scm-batch-processor
  })
 
  type = "STANDARD"
 
  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }
 
  tags = merge(
    local.global_vars.locals.aws_default_tags,
    local.owner_vars.locals.aws_default_tags,
    local.account_vars.locals.aws_default_tags,
    local.region_vars.locals.aws_default_tags,
    try(local.environment_vars.locals.s3_tags, {}),
    {
      "Component" = "${basename(get_terragrunt_dir())}",
      "Name"      = "${local.prefix}-${local.parent_directory}",
    }
  )
 
}
 