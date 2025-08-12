# Common variables
variable "region" {
  description = "AWS region for CloudWatch resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "gas"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "gas"
    ManagedBy   = "terraform"
  }
}

# Alarm naming convention variables
variable "customer" {
  description = "Customer name for alarm naming convention"
  type        = string
  default     = "enbd-preprod"
}

variable "team" {
  description = "Team name for alarm naming convention"
  type        = string
  default     = "DNA"
}

variable "severity_levels" {
  description = "Mapping of severity levels to alarm naming convention"
  type        = map(string)
  default = {
    high   = "Sev1"
    medium = "Sev2"
    low    = "Sev3"
    info   = "Sev4"
  }
}

# Dashboard variables
variable "dashboards" {
  description = "Map of CloudWatch dashboards to create"
  type = map(object({
    name           = string
    dashboard_body = string
    type           = optional(string, "custom")
    tags           = optional(map(string), {})
    linked_dashboards = optional(list(string), [])
  }))
  default = {}
}

# Alarm variables
variable "alarms" {
  description = "Map of CloudWatch alarms to create"
  type = map(object({
    alarm_name          = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_description   = optional(string)
    alarm_actions       = optional(list(string), [])
    ok_actions          = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    dimensions          = optional(list(object({
      name  = string
      value = string
    })), [])
    extended_statistic  = optional(string)
    threshold_metric_id = optional(string)
    treat_missing_data  = optional(string, "missing")
    unit                = optional(string)
    datapoints_to_alarm = optional(number)
    tags                = optional(map(string), {})
  }))
  default = {}
}

# Log Group variables
variable "log_groups" {
  description = "Map of CloudWatch log groups to create"
  type = map(object({
    name               = string
    retention_in_days  = optional(number, 14)
    kms_key_id         = optional(string)
    tags               = optional(map(string), {})
  }))
  default = {}
}

# Event Rule variables
variable "event_rules" {
  description = "Map of CloudWatch event rules to create"
  type = map(object({
    name                = string
    description         = optional(string)
    schedule_expression = optional(string)
    event_pattern       = optional(any)
    is_enabled          = optional(bool, true)
    role_arn            = optional(string)
    tags                = optional(map(string), {})
  }))
  default = {}
}

# Event Target variables
variable "event_targets" {
  description = "Map of CloudWatch event targets to create"
  type = map(object({
    rule_key = string
    target_id = string
    arn      = string
    input    = optional(string)
    input_path = optional(string)
    input_transformer = optional(object({
      input_paths    = map(string)
      input_template = string
    }))
    run_command_targets = optional(list(object({
      key    = string
      values = list(string)
    })), [])
    ecs_target = optional(object({
      task_count          = optional(number, 1)
      task_definition_arn = string
      launch_type         = optional(string, "FARGATE")
      platform_version    = optional(string, "LATEST")
      group               = optional(string)
      network_configuration = optional(object({
        subnets          = list(string)
        security_groups  = optional(list(string), [])
        assign_public_ip = optional(bool, false)
      }))
    }))
    lambda_target = optional(string)
    sqs_target = optional(object({
      message_group_id = string
    }))
  }))
  default = {}
}

# Default monitoring configurations
variable "default_monitoring" {
  description = "Default monitoring configurations for common resources"
  type = object({
    # Single database (simplified)
    database = optional(object({
      name = string
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple databases (map)
    databases = optional(map(object({
      name = string
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single lambda (simplified)
    lambda = optional(object({
      name = string
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple lambdas (map)
    lambdas = optional(map(object({
      name = string
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single SQS queue (simplified)
    sqs_queue = optional(object({
      name = string
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple SQS queues (map)
    sqs_queues = optional(map(object({
      name = string
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single ECS service (simplified)
    ecs_service = optional(object({
      name = string
      cluster_name = string
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple ECS services (map)
    ecs_services = optional(map(object({
      name = string
      cluster_name = string
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single EKS cluster (simplified)
    eks_cluster = optional(object({
      name = string
      region = optional(string, "us-east-1")
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple EKS clusters (map)
    eks_clusters = optional(map(object({
      name = string
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single EKS pod (simplified)
    eks_pod = optional(object({
      name = string
      namespace = optional(string, "default")
      cluster_name = string
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple EKS pods (map)
    eks_pods = optional(map(object({
      name = string
      namespace = optional(string, "default")
      cluster_name = string
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single EKS node group (simplified)
    eks_nodegroup = optional(object({
      name = string
      cluster_name = string
      asg_name = optional(string)  # Auto Scaling Group name for EC2 metrics
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple EKS node groups (map)
    eks_nodegroups = optional(map(object({
      name = string
      cluster_name = string
      asg_name = optional(string)  # Auto Scaling Group name for EC2 metrics
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single Step Function (simplified)
    step_function = optional(object({
      name = string
      arn = optional(string)
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple Step Functions (map)
    step_functions = optional(map(object({
      name = string
      arn = optional(string)
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single EC2 instance (simplified)
    ec2_instance = optional(object({
      name = string
      instance_id = optional(string)
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple EC2 instances (map)
    ec2_instances = optional(map(object({
      name = string
      instance_id = optional(string)
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single S3 bucket (simplified)
    s3_bucket = optional(object({
      name = string
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple S3 buckets (map)
    s3_buckets = optional(map(object({
      name = string
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single EventBridge rule (simplified)
    eventbridge_rule = optional(object({
      name = string
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    }))
    
    # Multiple EventBridge rules (map)
    eventbridge_rules = optional(map(object({
      name = string
      region = optional(string, "us-east-1")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarms = optional(list(string), [])  # Which alarms to include (empty = all)
      exclude_alarms = optional(list(string), [])  # Which alarms to exclude
      custom_alarms = optional(map(any), {})
      custom_metrics = optional(list(any), [])
    })), {})
    
    # Single log-based alarm (simplified)
    log_alarm = optional(object({
      log_group_name = string
      pattern = string
      transformation_name = string
      transformation_namespace = string
      transformation_value = string
      default_value = optional(string, "0")
      alarm_description = string
      comparison_operator = string
      evaluation_periods = number
      period = number
      statistic = string
      threshold = number
      treat_missing_data = optional(string, "notBreaching")
      unit = optional(string, "Count")
      severity = optional(string, "Sev2")
      sub_service = optional(string, "Custom")
      error_details = optional(string, "log-pattern-detected")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarm_actions = optional(list(string), [])
      ok_actions = optional(list(string), [])
      insufficient_data_actions = optional(list(string), [])
      dimensions = optional(list(object({
        name  = string
        value = string
      })), [])
    }))
    
    # Multiple log-based alarms (map)
    log_alarms = optional(map(object({
      log_group_name = string
      pattern = string
      transformation_name = string
      transformation_namespace = string
      transformation_value = string
      default_value = optional(string, "0")
      alarm_description = string
      comparison_operator = string
      evaluation_periods = number
      period = number
      statistic = string
      threshold = number
      treat_missing_data = optional(string, "notBreaching")
      unit = optional(string, "Count")
      severity = optional(string, "Sev2")
      sub_service = optional(string, "Custom")
      error_details = optional(string, "log-pattern-detected")
      customer = optional(string)  # Customer for alarm naming (defaults to var.customer)
      team = optional(string)      # Team for alarm naming (defaults to var.team)
      alarm_actions = optional(list(string), [])
      ok_actions = optional(list(string), [])
      insufficient_data_actions = optional(list(string), [])
      dimensions = optional(list(object({
        name  = string
        value = string
      })), [])
    })), {})
  })
  default = {}
}

# Dashboard linking configuration
variable "dashboard_links" {
  description = "Configuration for linking dashboards together"
  type = object({
    overview_dashboard = optional(object({
      name = string
      description = optional(string)
      include_all_alarms = optional(bool, true)
      include_all_metrics = optional(bool, true)
      custom_widgets = optional(list(any), [])
    }))
    link_groups = optional(map(object({
      name = string
      dashboards = list(string)
      description = optional(string)
    })), {})
  })
  default = {}
}



 