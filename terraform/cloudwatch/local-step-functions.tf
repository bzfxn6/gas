# Step Functions Monitoring Locals
# This file contains all Step Functions-related alarm definitions

locals {
  # Generate Step Functions alarms with dynamic naming
  step_function_alarms = merge([
    for sf_key, sf_config in local.all_step_functions : {
      for alarm_key, alarm_config in {
        execution_failures = {
          alarm_name = "Sev1/${coalesce(try(sf_config.customer, null), var.customer)}/${coalesce(try(sf_config.team, null), var.team)}/StepFunctions/Executions/execution-failures-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "ExecutionsFailed"
          namespace = "AWS/States"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "Step Function execution failures detected"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "Executions"
          error_details = "execution-failures-above-threshold"
        }
        execution_time = {
          alarm_name = "Sev2/${coalesce(try(sf_config.customer, null), var.customer)}/${coalesce(try(sf_config.team, null), var.team)}/StepFunctions/Duration/execution-time-above-5-minutes"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "ExecutionTime"
          namespace = "AWS/States"
          period = 300
          statistic = "Average"
          threshold = 300000
          alarm_description = "Step Function execution time is above 5 minutes"
          treat_missing_data = "notBreaching"
          unit = "Milliseconds"
          severity = "Sev2"
          sub_service = "Duration"
          error_details = "execution-time-above-5-minutes"
        }
        throttled_events = {
          alarm_name = "Sev2/${coalesce(try(sf_config.customer, null), var.customer)}/${coalesce(try(sf_config.team, null), var.team)}/StepFunctions/Throttles/throttled-events-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "ThrottledEvents"
          namespace = "AWS/States"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "Step Function throttled events detected"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "Throttles"
          error_details = "throttled-events-above-threshold"
        }
        activity_failures = {
          alarm_name = "Sev1/${coalesce(try(sf_config.customer, null), var.customer)}/${coalesce(try(sf_config.team, null), var.team)}/StepFunctions/Activities/activity-failures-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "ActivityFailed"
          namespace = "AWS/States"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "Step Function activity failures detected"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "Activities"
          error_details = "activity-failures-above-threshold"
        }
        service_integration_failures = {
          alarm_name = "Sev1/${coalesce(try(sf_config.customer, null), var.customer)}/${coalesce(try(sf_config.team, null), var.team)}/StepFunctions/ServiceIntegration/service-integration-failures-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "ServiceIntegrationFailed"
          namespace = "AWS/States"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "Step Function service integration failures detected"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "ServiceIntegration"
          error_details = "service-integration-failures-above-threshold"
        }
      } : "${sf_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "StateMachineArn"
          value = sf_config.name
        }]
      })
    }
  ]...)
}
