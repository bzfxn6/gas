# AWS Batch Terragrunt Configuration
# Based on the hybrid approach: Lambda for small chunks (≤290K), Batch for large chunks (>290K)

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
  account            = local.account_vars.locals.account
 
  # region vars
  aws_region = try(local.account_vars.locals.aws_region, "")
 
  # Global useful variables
  parent_directory = basename(get_terragrunt_dir())
 
  # module config - You'll need to add batch_ext to your modules.hcl
  module_url     = try(local.modules_vars.locals.module_urls.batch_ext, "git::https://github.com/your-org/terraform-aws-batch.git")
  module_version = try(local.modules_versions_vars.locals.module_versions.batch_ext, "v1.0.0")
 
  # Useful variables for this module
  prefix            = "${local.project}-${local.environment}"
  local_json_dir    = format("%s/%s-json", get_terragrunt_dir(), local.parent_directory)
  service_directory = basename(dirname(get_terragrunt_dir()))
  global_json_dir   = strcontains(local.local_json_dir, "-vpc") ? format("%s/_envcommon/resources/%s/%s/%s-json", dirname(find_in_parent_folders()), local.environment_vars.locals.vpc_name, local.service_directory, local.parent_directory) : format("%s/_envcommon/resources/_global/%s-json", dirname(find_in_parent_folders()), local.parent_directory)
}

terraform {
  source = "${local.module_url}?ref=${module_version}"
}

dependency "iam_roles" {
  config_path                             = format("%s/%s/%s/%s/%s/app/iam-roles", dirname(find_in_parent_folders()), local.project, local.environment, local.aws_region, local.environment_vars.locals.vpc_name)
  mock_outputs_allowed_terraform_commands = ["validate", "show", "plan", "init"]
  mock_outputs_merge_strategy_with_state  = "deep_map_only"
  mock_outputs = {
    role_arn = {
      scm-batch-processor-batch-role = "arn:aws:iam::123456789012:role/mock-scm-batch-processor-batch-role"
      scm-batch-processor-batch-instance-role = "arn:aws:iam::123456789012:instance-profile/mock-scm-batch-processor-batch-instance-role"
    }
  }
}

dependency "security_group" {
  config_path                             = format("%s/%s/%s/%s/%s/app/security-group", dirname(find_in_parent_folders()), local.project, local.environment, local.aws_region, local.environment_vars.locals.vpc_name)
  mock_outputs_allowed_terraform_commands = ["validate", "show", "plan", "init"]
  mock_outputs_merge_strategy_with_state  = "deep_map_only"
  mock_outputs = {
    security_group_ids = {
      scm-batch-processor-batch = "sg-77777777777"
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
        vpc_id = "vpc-1234567890123456"
      }
      "msk" = {
        bootstrap_brokers_iam = "b-1.example-cluster.kafka.eu-west-1.amazonaws.com:9098,b-2.example-cluster.kafka.eu-west-1.amazonaws.com:9098"
      }
    }
  }
}

inputs = {
  items = merge({
    for batch in fileset("${local.local_json_dir}", "*.json") :
    trimsuffix(batch, ".json") => jsondecode(templatefile("${local.local_json_dir}/${batch}",
      {
        AWS_ACCOUNT_NAME                            = local.aws_account_number
        ACCOUNT_OWNER                               = local.project
        BATCH_PATH                                  = get_terragrunt_dir()
        SCM_BATCH_PROCESSOR_BATCH_ROLE              = dependency.iam_roles.outputs.role_arn.scm-batch-processor-batch-role
        SCM_BATCH_PROCESSOR_BATCH_INSTANCE_ROLE     = dependency.iam_roles.outputs.role_arn.scm-batch-processor-batch-instance-role
        SCM_BATCH_PROCESSOR_BATCH_SG                = dependency.security_group.outputs.security_group_ids.scm-batch-processor-batch
        PREFIX                                      = local.prefix
        SUBNETS                                     = jsonencode(dependency.state_file_outputs.outputs.map_output.base.subnets.app)
        VPC_ID                                      = dependency.state_file_outputs.outputs.map_output.base.vpc_id
        MSK_BROKERS = replace(
          jsonencode([
            for broker in split(",", dependency.state_file_outputs.outputs.map_output.msk.bootstrap_brokers_iam) :
            trimspace(broker)
          ]),
          "\"", "\\\""
        )
        MSK_TOPIC      = "${local.gss_account}-ws-ag-screening_request"
        SQS_CORE_QUEUE = "${local.account}-dmz-il-request"
        RECORD_DESTINATION = "kafka"  # or "sqs_core" - configurable
        AWS_REGION     = local.aws_region
        TAGS = jsonencode(merge(local.global_vars.locals.aws_default_tags,
          local.owner_vars.locals.aws_default_tags,
          local.account_vars.locals.aws_default_tags,
          try(local.region_vars.locals.aws_default_tags, {}),
          try(local.environment_vars.locals.aws_default_tags, {}),
        { "Component" = "${basename(dirname(get_terragrunt_dir()))}/${basename(get_terragrunt_dir())}" }))
      }
    ))
    }, { for batch in fileset("${local.global_json_dir}", "*.json") :
    trimsuffix(batch, ".json") => jsondecode(templatefile("${local.global_json_dir}/${batch}",
      {
        AWS_ACCOUNT_NAME                            = local.aws_account_number
        ACCOUNT_OWNER                               = local.project
        BATCH_PATH                                  = get_terragrunt_dir()
        SCM_BATCH_PROCESSOR_BATCH_ROLE              = dependency.iam_roles.outputs.role_arn.scm-batch-processor-batch-role
        SCM_BATCH_PROCESSOR_BATCH_INSTANCE_ROLE     = dependency.iam_roles.outputs.role_arn.scm-batch-processor-batch-instance-role
        SCM_BATCH_PROCESSOR_BATCH_SG                = dependency.security_group.outputs.security_group_ids.scm-batch-processor-batch
        PREFIX                                      = local.prefix
        SUBNETS                                     = jsonencode(dependency.state_file_outputs.outputs.map_output.base.subnets.app)
        VPC_ID                                      = dependency.state_file_outputs.outputs.map_output.base.vpc_id
        MSK_BROKERS = replace(
          jsonencode([
            for broker in split(",", dependency.state_file_outputs.outputs.map_output.msk.bootstrap_brokers_iam) :
            trimspace(broker)
          ]),
          "\"", "\\\""
        )
        MSK_TOPIC      = "${local.gss_account}-ws-ag-screening_request"
        SQS_CORE_QUEUE = "${local.account}-dmz-il-request"
        RECORD_DESTINATION = "kafka"  # or "sqs_core" - configurable
        AWS_REGION     = local.aws_region
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