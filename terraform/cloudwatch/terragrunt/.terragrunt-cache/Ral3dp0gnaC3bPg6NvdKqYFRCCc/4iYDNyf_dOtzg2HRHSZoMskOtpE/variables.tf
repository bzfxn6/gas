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

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "create_dashboard" {
  description = "Whether to create a CloudWatch dashboard"
  type        = bool
  default     = false
}

variable "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  type        = string
  default     = "cloudwatch-dashboard"
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
  type = any
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
  type = any
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



 
# Default alarm actions
variable "default_alarm_actions" {
  description = "Default actions to take when alarms are triggered (e.g., SNS topic ARNs)"
  type = list(string)
  default = []
}

variable "default_ok_actions" {
  description = "Default actions to take when alarms return to OK state"
  type = list(string)
  default = []
}

variable "default_insufficient_data_actions" {
  description = "Default actions to take when alarms have insufficient data"
  type = list(string)
  default = []
}
