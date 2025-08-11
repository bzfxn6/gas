# Step Functions Monitoring Template
# This template provides default monitoring for AWS Step Functions

# Default Step Function monitoring configuration
locals {
  step_function_alarms = {
    execution_success_rate = {
      alarm_name          = "step-function-execution-success-rate"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ExecutionSucceeded"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 95
      alarm_description   = "Step Function execution success rate is below 95%"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    execution_failure_rate = {
      alarm_name          = "step-function-execution-failure-rate"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "ExecutionFailed"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "Step Function has execution failures"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    execution_throttled = {
      alarm_name          = "step-function-execution-throttled"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "ExecutionThrottled"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "Step Function executions are being throttled"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    execution_time = {
      alarm_name          = "step-function-execution-time"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ExecutionTime"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Average"
      threshold           = 300000  # 5 minutes in milliseconds
      alarm_description   = "Step Function execution time is above 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Milliseconds"
    }
    execution_aborted = {
      alarm_name          = "step-function-execution-aborted"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "ExecutionAborted"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "Step Function executions are being aborted"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    execution_timed_out = {
      alarm_name          = "step-function-execution-timed-out"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "ExecutionTimedOut"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "Step Function executions are timing out"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    activity_failed = {
      alarm_name          = "step-function-activity-failed"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "ActivityFailed"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "Step Function activities are failing"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    activity_scheduled = {
      alarm_name          = "step-function-activity-scheduled"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ActivityScheduled"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 100
      alarm_description   = "Step Function has more than 100 scheduled activities"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    activity_started = {
      alarm_name          = "step-function-activity-started"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ActivityStarted"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 100
      alarm_description   = "Step Function has more than 100 started activities"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    activity_succeeded = {
      alarm_name          = "step-function-activity-succeeded"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ActivitySucceeded"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 95
      alarm_description   = "Step Function activity success rate is below 95%"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    activity_time = {
      alarm_name          = "step-function-activity-time"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ActivityTime"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Average"
      threshold           = 60000  # 1 minute in milliseconds
      alarm_description   = "Step Function activity time is above 1 minute"
      treat_missing_data = "notBreaching"
      unit                = "Milliseconds"
    }
    lambda_function_failed = {
      alarm_name          = "step-function-lambda-function-failed"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "LambdaFunctionFailed"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "Step Function Lambda functions are failing"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    lambda_function_scheduled = {
      alarm_name          = "step-function-lambda-function-scheduled"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "LambdaFunctionScheduled"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 100
      alarm_description   = "Step Function has more than 100 scheduled Lambda functions"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    lambda_function_started = {
      alarm_name          = "step-function-lambda-function-started"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "LambdaFunctionStarted"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 100
      alarm_description   = "Step Function has more than 100 started Lambda functions"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    lambda_function_succeeded = {
      alarm_name          = "step-function-lambda-function-succeeded"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "LambdaFunctionSucceeded"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 95
      alarm_description   = "Step Function Lambda function success rate is below 95%"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    lambda_function_time = {
      alarm_name          = "step-function-lambda-function-time"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "LambdaFunctionTime"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Average"
      threshold           = 30000  # 30 seconds in milliseconds
      alarm_description   = "Step Function Lambda function time is above 30 seconds"
      treat_missing_data = "notBreaching"
      unit                = "Milliseconds"
    }
    service_integration_failed = {
      alarm_name          = "step-function-service-integration-failed"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "ServiceIntegrationFailed"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "Step Function service integrations are failing"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    service_integration_scheduled = {
      alarm_name          = "step-function-service-integration-scheduled"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ServiceIntegrationScheduled"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 100
      alarm_description   = "Step Function has more than 100 scheduled service integrations"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    service_integration_started = {
      alarm_name          = "step-function-service-integration-started"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ServiceIntegrationStarted"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 100
      alarm_description   = "Step Function has more than 100 started service integrations"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    service_integration_succeeded = {
      alarm_name          = "step-function-service-integration-succeeded"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ServiceIntegrationSucceeded"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Sum"
      threshold           = 95
      alarm_description   = "Step Function service integration success rate is below 95%"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    service_integration_time = {
      alarm_name          = "step-function-service-integration-time"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ServiceIntegrationTime"
      namespace           = "AWS/States"
      period              = 300
      statistic           = "Average"
      threshold           = 60000  # 1 minute in milliseconds
      alarm_description   = "Step Function service integration time is above 1 minute"
      treat_missing_data = "notBreaching"
      unit                = "Milliseconds"
    }
  }
}

# Generate alarms for Step Functions
locals {
  step_function_monitoring = merge([
    for sf_key, sf_config in local.all_step_functions : {
      for alarm_key, alarm_config in local.step_function_alarms : "${sf_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${sf_config.name}-${alarm_config.alarm_name}"
        dimensions = [
          {
            name  = "StateMachineArn"
            value = sf_config.arn != null ? sf_config.arn : "arn:aws:states:${var.region}:${data.aws_caller_identity.current.account_id}:stateMachine:${sf_config.name}"
          }
        ]
      })
      # Filter alarms based on user selection
      if length(sf_config.alarms) == 0 || contains(sf_config.alarms, alarm_key)
      # Exclude alarms if specified
      if !contains(coalesce(sf_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}

# Generate default dashboard widgets for Step Functions
locals {
  step_function_dashboard_widgets = [
    for sf_key, sf_config in local.all_step_functions : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/States", "ExecutionSucceeded", "StateMachineArn", sf_config.arn != null ? sf_config.arn : "arn:aws:states:${var.region}:${data.aws_caller_identity.current.account_id}:stateMachine:${sf_config.name}"],
          [".", "ExecutionFailed", ".", "."],
          [".", "ExecutionThrottled", ".", "."],
          [".", "ExecutionTime", ".", "."],
          [".", "ExecutionAborted", ".", "."],
          [".", "ExecutionTimedOut", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${sf_config.name} Step Function Execution Metrics"
      }
    }
  ]
}

# Generate activity monitoring widgets for Step Functions
locals {
  step_function_activity_widgets = [
    for sf_key, sf_config in local.all_step_functions : {
      type   = "metric"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/States", "ActivityScheduled", "StateMachineArn", sf_config.arn != null ? sf_config.arn : "arn:aws:states:${var.region}:${data.aws_caller_identity.current.account_id}:stateMachine:${sf_config.name}"],
          [".", "ActivityStarted", ".", "."],
          [".", "ActivitySucceeded", ".", "."],
          [".", "ActivityFailed", ".", "."],
          [".", "ActivityTime", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${sf_config.name} Step Function Activity Metrics"
      }
    }
  ]
}

# Generate Lambda integration widgets for Step Functions
locals {
  step_function_lambda_widgets = [
    for sf_key, sf_config in local.all_step_functions : {
      type   = "metric"
      x      = 0
      y      = 6
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/States", "LambdaFunctionScheduled", "StateMachineArn", sf_config.arn != null ? sf_config.arn : "arn:aws:states:${var.region}:${data.aws_caller_identity.current.account_id}:stateMachine:${sf_config.name}"],
          [".", "LambdaFunctionStarted", ".", "."],
          [".", "LambdaFunctionSucceeded", ".", "."],
          [".", "LambdaFunctionFailed", ".", "."],
          [".", "LambdaFunctionTime", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${sf_config.name} Step Function Lambda Integration Metrics"
      }
    }
  ]
}

# Generate service integration widgets for Step Functions
locals {
  step_function_service_widgets = [
    for sf_key, sf_config in local.all_step_functions : {
      type   = "metric"
      x      = 12
      y      = 6
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/States", "ServiceIntegrationScheduled", "StateMachineArn", sf_config.arn != null ? sf_config.arn : "arn:aws:states:${var.region}:${data.aws_caller_identity.current.account_id}:stateMachine:${sf_config.name}"],
          [".", "ServiceIntegrationStarted", ".", "."],
          [".", "ServiceIntegrationSucceeded", ".", "."],
          [".", "ServiceIntegrationFailed", ".", "."],
          [".", "ServiceIntegrationTime", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${sf_config.name} Step Function Service Integration Metrics"
      }
    }
  ]
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}
