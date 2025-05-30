# Add variable validations
variable "sns_topics" {
  description = "Map of SNS topics and their configurations"
  type = map(object({
    fifo_queue                        = optional(bool, false)
    max_message_size                  = optional(number, 262144)
    message_retention_seconds         = optional(number, 345600)
    receive_wait_time_seconds         = optional(number, 0)
    delay_seconds                     = optional(number, 0)
    kms_master_key_id                 = optional(string)
    kms_data_key_reuse_period_seconds = optional(number, 300)
    sqs_managed_sse_enabled           = optional(bool, true)
    deadletter                        = optional(bool, false)
    max_receive_count                 = optional(number, 5)
    resource_based_policy_enabled     = optional(bool, false)
    custom_iam_policy                 = optional(string, "")
    custom_iam_policy_for_dlq         = optional(string, "")
    s3_send_allowed_arns             = optional(list(string), [])
    sns_send_allowed_arns            = optional(list(string), [])
    iam_send_allowed_arns            = optional(list(string), [])
    manage_allowed_arns              = optional(list(string), [])
    read_allowed_arns                = optional(list(string), [])
    ssm_name                         = optional(string)
    tags                             = optional(map(string), {})
  }))
  default = {}
  validation {
    condition     = alltrue([for v in var.sns_topics : v.max_message_size >= 1024 && v.max_message_size <= 262144])
    error_message = "max_message_size must be between 1024 and 262144 bytes"
  }
  validation {
    condition     = alltrue([for v in var.sns_topics : v.message_retention_seconds >= 60 && v.message_retention_seconds <= 1209600])
    error_message = "message_retention_seconds must be between 60 and 1209600 seconds"
  }
  validation {
    condition     = alltrue([for v in var.sns_topics : v.receive_wait_time_seconds >= 0 && v.receive_wait_time_seconds <= 20])
    error_message = "receive_wait_time_seconds must be between 0 and 20 seconds"
  }
  validation {
    condition     = alltrue([for v in var.sns_topics : v.delay_seconds >= 0 && v.delay_seconds <= 900])
    error_message = "delay_seconds must be between 0 and 900 seconds"
  }
  validation {
    condition     = alltrue([for v in var.sns_topics : v.max_receive_count >= 1 && v.max_receive_count <= 1000])
    error_message = "max_receive_count must be between 1 and 1000"
  }
}

variable "resource_prefix" {
  description = "Prefix to be used for all resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.resource_prefix))
    error_message = "resource_prefix must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "aws_number_account" {
  description = "AWS account number"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_number_account))
    error_message = "aws_number_account must be a 12-digit number"
  }
}

variable "custom_prefix" {
  description = "Custom prefix for SSM parameters"
  type        = string
  default     = ""
  validation {
    condition     = var.custom_prefix == "" || can(regex("^[a-z0-9-]+$", var.custom_prefix))
    error_message = "custom_prefix must be empty or contain only lowercase letters, numbers, and hyphens"
  }
}

# Add locals for common values
locals {
  queue_name = {
    for k, v in var.sns_topics : k => v.fifo_queue ? "${var.resource_prefix}-${k}.fifo" : "${var.resource_prefix}-${k}"
  }
  dlq_name = {
    for k, v in var.sns_topics : k => "${var.resource_prefix}-${k}-dlq"
  }
  queue_arn = {
    for k, v in var.sns_topics : k => "arn:aws:sqs:${var.region}:${var.aws_number_account}:${local.queue_name[k]}"
  }
}

# Update the SQS queue resources to use locals
resource "aws_sqs_queue" "deadletter_queue" {
  for_each = {
    for sns_topic, sns_config in var.sns_topics :
    sns_topic => sns_config if sns_config.deadletter
  }
  name                              = local.dlq_name[each.key]
  fifo_queue                        = each.value.fifo_queue
  kms_master_key_id                 = each.value.kms_master_key_id
  kms_data_key_reuse_period_seconds = each.value.kms_data_key_reuse_period_seconds
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [local.queue_arn[each.key]]
  })
  tags = merge(
    each.value.tags,
    {
      Name        = local.dlq_name[each.key]
      Environment = var.resource_prefix
      Service     = "SQS"
      Type        = "DLQ"
    }
  )
}

resource "aws_sqs_queue" "sqs_queue" {
  for_each                          = var.sns_topics
  name                              = local.queue_name[each.key]
  max_message_size                  = each.value.max_message_size
  message_retention_seconds         = each.value.message_retention_seconds
  receive_wait_time_seconds         = each.value.receive_wait_time_seconds
  fifo_queue                        = each.value.fifo_queue
  sqs_managed_sse_enabled           = each.value.kms_master_key_id != null ? null : each.value.sqs_managed_sse_enabled
  kms_master_key_id                 = each.value.kms_master_key_id
  kms_data_key_reuse_period_seconds = each.value.kms_data_key_reuse_period_seconds
  delay_seconds                     = each.value.delay_seconds
  redrive_policy = each.value.deadletter ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue[each.key].arn
    maxReceiveCount     = each.value.max_receive_count
  }) : null
  tags = merge(
    each.value.tags,
    {
      Name        = local.queue_name[each.key]
      Environment = var.resource_prefix
      Service     = "SQS"
      Type        = "Standard"
    }
  )
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  for_each = {
    for sns_topic, sns_config in var.sns_topics :
    sns_topic => sns_config if sns_config.resource_based_policy_enabled && (
      sns_config.custom_iam_policy != "" || 
      try(length(sns_config.s3_send_allowed_arns), 0) > 0 ||
      try(length(sns_config.sns_send_allowed_arns), 0) > 0 ||
      try(length(sns_config.iam_send_allowed_arns), 0) > 0 ||
      try(length(sns_config.manage_allowed_arns), 0) > 0 ||
      try(length(sns_config.read_allowed_arns), 0) > 0
    )
  }
  queue_url = aws_sqs_queue.sqs_queue[each.key].id
  policy    = each.value.custom_iam_policy != "" ? each.value.custom_iam_policy : data.aws_iam_policy_document.sqs_policy[each.key].json
}
 
resource "aws_sqs_queue_policy" "sqs_dlq_queue_policy" {
  for_each = {
    for sns_topic, sns_config in var.sns_topics :
    sns_topic => sns_config if sns_config.resource_based_policy_enabled && sns_config.deadletter && (
      sns_config.custom_iam_policy_for_dlq != "" || 
      try(length(sns_config.s3_send_allowed_arns), 0) > 0 ||
      try(length(sns_config.sns_send_allowed_arns), 0) > 0 ||
      try(length(sns_config.iam_send_allowed_arns), 0) > 0 ||
      try(length(sns_config.manage_allowed_arns), 0) > 0 ||
      try(length(sns_config.read_allowed_arns), 0) > 0
    )
  }
  queue_url = aws_sqs_queue.deadletter_queue[each.key].id
  policy    = each.value.custom_iam_policy_for_dlq != "" ? each.value.custom_iam_policy_for_dlq : data.aws_iam_policy_document.sqs_policy[each.key].json
}
 
# Check to see if ssm_name is in the map file, if it is create a ssm parameter with the role name and using the name provided
# the ssm parameter will hold the role ARN, used within helm charts
resource "aws_ssm_parameter" "service_role" {
  for_each = {
    for key, role in var.sns_topics :
    key => role if contains(keys(role), "ssm_name")
  }
  name  = var.custom_prefix != "" ? "/${var.custom_prefix}/sqs/${aws_sqs_queue.sqs_queue[each.key].name}" : "/${var.resource_prefix}-${each.value.ssm_name}/sqs/${aws_sqs_queue.sqs_queue[each.key].name}"
  type  = "String"
  value = aws_sqs_queue.sqs_queue[each.key].url
}
 
 
data "aws_iam_policy_document" "sqs_policy" {
  for_each = var.sns_topics
 
  dynamic "statement" {
    for_each = try(length(each.value.s3_send_allowed_arns), 0) > 0 ? [1] : []
    content {
      sid       = "AllowS3Send-${each.key}"
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.sqs_queue[each.key].arn]
      principals {
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }
      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = each.value.s3_send_allowed_arns
      }
    }
  }
 
  dynamic "statement" {
    for_each = try(length(each.value.sns_send_allowed_arns), 0) > 0 ? [1] : []
    content {
      sid       = "AllowSNSSend-${each.key}"
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.sqs_queue[each.key].arn]
      principals {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }
      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = each.value.sns_send_allowed_arns
      }
    }
  }
 
  dynamic "statement" {
    for_each = try(length(each.value.iam_send_allowed_arns), 0) > 0 ? [1] : []
    content {
      sid       = "AllowIAMSend-${each.key}"
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.sqs_queue[each.key].arn]
      principals {
        type        = "AWS"
        identifiers = each.value.iam_send_allowed_arns
      }
    }
  }
 
  dynamic "statement" {
    for_each = try(length(each.value.manage_allowed_arns), 0) > 0 ? [1] : []
    content {
      sid    = "AllowManage-${each.key}"
      effect = "Allow"
      actions = [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:ReceiveMessage",
        "sqs:SendMessage",
        "sqs:GetQueueUrl",
      ]
      resources = [aws_sqs_queue.sqs_queue[each.key].arn]
      principals {
        type        = "AWS"
        identifiers = each.value.manage_allowed_arns
      }
    }
  }
 
  dynamic "statement" {
    for_each = try(length(each.value.read_allowed_arns), 0) > 0 ? [1] : []
    content {
      sid    = "AllowRead-${each.key}"
      effect = "Allow"
      actions = [
        "sqs:DeleteMessage",
        "sqs:ReceiveMessage",
        "sqs:GetQueueUrl",
      ]
      resources = [aws_sqs_queue.sqs_queue[each.key].arn]
      principals {
        type        = "AWS"
        identifiers = each.value.read_allowed_arns
      }
    }
  }
}