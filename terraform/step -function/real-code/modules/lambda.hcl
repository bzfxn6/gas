
locals {
  global_vars           = try(read_terragrunt_config(find_in_parent_folders("global.hcl")), {})
  owner_vars            = try(read_terragrunt_config(find_in_parent_folders("owner.hcl")), {})
  account_vars          = try(read_terragrunt_config(find_in_parent_folders("account.hcl")), {})
  region_vars           = try(read_terragrunt_config(find_in_parent_folders("region.hcl")), {})
  environment_vars      = try(read_terragrunt_config(find_in_parent_folders("env.hcl")), {})
  modules_vars          = try(read_terragrunt_config(find_in_parent_folders("modules.hcl")), {})
  modules_versions_vars = try(read_terragrunt_config(find_in_parent_folders("version.hcl")), {})
 
  # set variables from shared files for easy of use.
  # owner vars
  project = local.owner_vars.locals.project
  # account vars
  aws_account_number = local.account_vars.locals.aws_account_number
  environment        = local.account_vars.locals.environment
  gss_account        = local.account_vars.locals.gss_account
  account            = local.account_vars.locals.account
 
  # region vars
  aws_region = try(local.account_vars.locals.aws_region, "")
 
  # Global useful variables
  parent_directory = basename(get_terragrunt_dir())
 
  # module config
  module_url     = local.modules_vars.locals.module_urls.lambda_ext
  module_version = local.modules_versions_vars.locals.module_versions.lambda_ext
 
  # Useful variables for this module
  prefix            = "${local.project}-${local.environment}"
  local_json_dir    = format("%s/%s-json", get_terragrunt_dir(), local.parent_directory)
  service_directory = basename(dirname(get_terragrunt_dir()))
  global_json_dir   = strcontains(local.local_json_dir, "-vpc") ? format("%s/_envcommon/resources/%s/%s/%s-json", dirname(find_in_parent_folders()), local.environment_vars.locals.vpc_name, local.service_directory, local.parent_directory) : format("%s/_envcommon/resources/_global/%s-json", dirname(find_in_parent_folders()), local.parent_directory)
}
 
terraform {
  source = "${local.module_url}?ref=${local.module_version}"
 
  # May use Hook to tar lambda files, TBC
  # before_hook "copy_lambda" {
  #   commands = ["init", "apply"]
  #   #execute = ["cp", "${get_terragrunt_dir()}/lambda_function.py", "${get_parent_terragrunt_dir()}/lambda_function.py"]
  #   execute = ["pwd"]
  # }
}
 
dependency "iam_roles" {
  config_path                             = format("%s/%s/%s/%s/%s/app/iam-roles", dirname(find_in_parent_folders()), local.project, local.environment, local.aws_region, local.environment_vars.locals.vpc_name)
  mock_outputs_allowed_terraform_commands = ["validate", "show", "plan", "init"]
  mock_outputs_merge_strategy_with_state  = "deep_map_only"
  mock_outputs = {
    role_arn = {
      scm-batch-processor-read-s3          = "arn:aws:iam::123456789012:instance-profile/mock-scm-batch-processor-read-s3"
      scm-batch-processor-update-records   = "arn:aws:iam::123456789012:instance-profile/mock-scm-batch-processor-update-records"
      scm-batch-processor-send-to-sqs-core = "arn:aws:iam::123456789012:instance-profile/mock-scm-batch-processor-send-to-sqs-core"
      scm-batch-processor-send-to-kafka    = "arn:aws:iam::123456789012:instance-profile/mock-scm-batch-processor-send-to-kafka"
    }
  }
}
 
dependency "lambda_layer" {
  config_path                             = "${get_original_terragrunt_dir()}/../lambda-layers"
  mock_outputs_allowed_terraform_commands = ["validate", "show", "plan", "init"]
  mock_outputs_merge_strategy_with_state  = "deep_map_only"
  mock_outputs = {
    wrapper = {
      scm-batch-processor-send-to-kafka = {
        lambda_layer_arn = "arn:aws:lambda:eu-west-2:123456789123:layer:gss-mock-scm-batch-processor-send-to-kafka-dev:1"
      }
      scm-batch-processor-send-to-sqs-core = {
        lambda_layer_arn = "arn:aws:lambda:eu-west-2:123456789123:layer:gss-mock-scm-batch-processor-send-to-sqs-core:1"
      }
    }
  }
}
 
dependency "security_group" {
  config_path                             = format("%s/%s/%s/%s/%s/app/security-group", dirname(find_in_parent_folders()), local.project, local.environment, local.aws_region, local.environment_vars.locals.vpc_name)
  mock_outputs_allowed_terraform_commands = ["validate", "show", "plan", "init"]
  mock_outputs_merge_strategy_with_state  = "deep_map_only"
  mock_outputs = {
    security_group_ids = {
      scm-batch-processor-send-to-kafka = "sg-77777777777"
    }
  }
}
 
dependency "state_file_outputs" {
  config_path                             = format("%s/%s/%s/data", dirname(find_in_parent_folders()), local.project, local.environment)
  mock_outputs_allowed_terraform_commands = ["validate", "show", "plan", "init"]
  mock_outputs_merge_strategy_with_state  = "deep_map_only"
  mock_outputs = {
    map_output = {
      "eks" = {
        eks_main_security_group_id = "sg-66666666666"
      }
      "base" = {
        subnets = {
          app = [
            "subnet-66666666666",
            "subnet-77777777777"
          ]
        }
      }
    }
  }
}
 
inputs = {
  items = merge({
    for lambda in fileset("${local.local_json_dir}", "*.json") :
    trimsuffix(lambda, ".json") => jsondecode(templatefile("${local.local_json_dir}/${lambda}",
      {
        AWS_ACCOUNT_NAME                            = local.aws_account_number
        ACCOUNT_OWNER                               = local.project
        LAMBDA_PATH                                 = get_terragrunt_dir()
        SCM_BATCH_PROCESSOR_READ_S3                 = dependency.iam_roles.outputs.role_arn.scm-batch-processor-read-s3
        SCM_BATCH_PROCESSOR_UPDATE_RECORDS          = dependency.iam_roles.outputs.role_arn.scm-batch-processor-update-records
        SCM_BATCH_PROCESSOR_SEND_TO_KAFKA           = dependency.iam_roles.outputs.role_arn.scm-batch-processor-send-to-kafka
        SCM_BATCH_PROCESSOR_SEND_TO_KAFKA_SG        = dependency.security_group.outputs.security_group_ids.scm-batch-processor-send-to-kafka
        SCM_BATCH_PROCESSOR_SEND_TO_SQS_CORE        = dependency.iam_roles.outputs.role_arn.scm-batch-processor-send-to-sqs-core
        PREFIX                                      = local.prefix
        SCM_BATCH_PROCESSOR_SEND_TO_KAFKA_DEV_LAYER = dependency.lambda_layer.outputs.wrapper.scm-batch-processor-send-to-kafka.lambda_layer_arn
        SCM_BATCH_PROCESSOR_SEND_TO_SQS_CORE_LAYER  = dependency.lambda_layer.outputs.wrapper.scm-batch-processor-send-to-sqs-core.lambda_layer_arn
        SUBNETS                                     = jsonencode(dependency.state_file_outputs.outputs.map_output.base.subnets.app)
        #MSK_BROKERS                         = jsonencode(split(",", dependency.state_file_outputs.outputs.map_output.msk.bootstrap_brokers_iam))
        MSK_BROKERS = replace(
          jsonencode([
            for broker in split(",", dependency.state_file_outputs.outputs.map_output.msk.bootstrap_brokers_iam) :
            trimspace(broker)
          ]),
          "\"", "\\\""
        )
        MSK_TOPIC      = "${local.gss_account}-ws-ag-screening_request"
        SQS_CORE_QUEUE = "${local.account}-dmz-il-request"
        TAGS = jsonencode(merge(local.global_vars.locals.aws_default_tags,
          local.owner_vars.locals.aws_default_tags,
          local.account_vars.locals.aws_default_tags,
          try(local.region_vars.locals.aws_default_tags, {}),
          try(local.environment_vars.locals.aws_default_tags, {}),
        { "Component" = "${basename(dirname(get_terragrunt_dir()))}/${basename(get_terragrunt_dir())}" }))
        #TAGS = jsonencode({ "Component" = "${basename(dirname(get_terragrunt_dir()))}/${basename(get_terragrunt_dir())}" })
      }
    ))
    }, { for lambda in fileset("${local.global_json_dir}", "*.json") :
    trimsuffix(lambda, ".json") => jsondecode(templatefile("${local.global_json_dir}/${lambda}",
      {
        AWS_ACCOUNT_NAME                            = local.aws_account_number
        ACCOUNT_OWNER                               = local.project
        LAMBDA_PATH                                 = get_terragrunt_dir()
        SCM_BATCH_PROCESSOR_READ_S3                 = dependency.iam_roles.outputs.role_arn.scm-batch-processor-read-s3
        SCM_BATCH_PROCESSOR_UPDATE_RECORDS          = dependency.iam_roles.outputs.role_arn.scm-batch-processor-update-records
        SCM_BATCH_PROCESSOR_SEND_TO_KAFKA           = dependency.iam_roles.outputs.role_arn.scm-batch-processor-send-to-kafka
        SCM_BATCH_PROCESSOR_SEND_TO_KAFKA_SG        = dependency.security_group.outputs.security_group_ids.scm-batch-processor-send-to-kafka
        SCM_BATCH_PROCESSOR_SEND_TO_SQS_CORE        = dependency.iam_roles.outputs.role_arn.scm-batch-processor-send-to-sqs-core
        PREFIX                                      = local.prefix
        SCM_BATCH_PROCESSOR_SEND_TO_KAFKA_DEV_LAYER = dependency.lambda_layer.outputs.wrapper.scm-batch-processor-send-to-kafka.lambda_layer_arn
        SCM_BATCH_PROCESSOR_SEND_TO_SQS_CORE_LAYER  = dependency.lambda_layer.outputs.wrapper.scm-batch-processor-send-to-sqs-core.lambda_layer_arn
        SUBNETS                                     = jsonencode(dependency.state_file_outputs.outputs.map_output.base.subnets.app)
        #MSK_BROKERS                         = jsonencode(split(",", dependency.state_file_outputs.outputs.map_output.msk.bootstrap_brokers_iam))
        MSK_BROKERS = replace(
          jsonencode([
            for broker in split(",", dependency.state_file_outputs.outputs.map_output.msk.bootstrap_brokers_iam) :
            trimspace(broker)
          ]),
          "\"", "\\\""
        )
        MSK_TOPIC      = "${local.gss_account}-ws-ag-screening_request"
        SQS_CORE_QUEUE = "${local.account}-dmz-il-request"
        TAGS = jsonencode(merge(local.global_vars.locals.aws_default_tags,
          local.owner_vars.locals.aws_default_tags,
          local.account_vars.locals.aws_default_tags,
          try(local.region_vars.locals.aws_default_tags, {}),
          try(local.environment_vars.locals.aws_default_tags, {}),
        { "Component" = "${basename(dirname(get_terragrunt_dir()))}/${basename(get_terragrunt_dir())}" }))
      }
    ))
  })
 
}
 
 
 