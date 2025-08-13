# EventBridge Rules Monitoring Locals
# This file contains all EventBridge rules-related alarm definitions

locals {
  # Generate EventBridge rules alarms with dynamic naming
  eventbridge_alarms = merge([
    for eb_key, eb_config in local.all_eventbridge_rules : {
      for alarm_key, alarm_config in {
        failed_invocations = {
          alarm_name = "Sev1/${coalesce(try(eb_config.customer, null), var.customer)}/${coalesce(try(eb_config.team, null), var.team)}/EventBridge/FailedInvocations/failed-invocations-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "FailedInvocations"
          namespace = "AWS/Events"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "EventBridge rule failed invocations detected"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "FailedInvocations"
          error_details = "failed-invocations-above-threshold"
        }
        throttled_events = {
          alarm_name = "Sev2/${coalesce(try(eb_config.customer, null), var.customer)}/${coalesce(try(eb_config.team, null), var.team)}/EventBridge/ThrottledEvents/throttled-events-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "ThrottledEvents"
          namespace = "AWS/Events"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "EventBridge rule throttled events detected"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "ThrottledEvents"
          error_details = "throttled-events-above-threshold"
        }
        dead_letter_invocations = {
          alarm_name = "Sev1/${coalesce(try(eb_config.customer, null), var.customer)}/${coalesce(try(eb_config.team, null), var.team)}/EventBridge/DeadLetterInvocations/dead-letter-invocations-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "DeadLetterInvocations"
          namespace = "AWS/Events"
          period = 300
          statistic = "Sum"
          threshold = 0
          alarm_description = "EventBridge rule dead letter invocations detected"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev1"
          sub_service = "DeadLetterInvocations"
          error_details = "dead-letter-invocations-above-threshold"
        }
        triggered_rules = {
          alarm_name = "Sev2/${coalesce(try(eb_config.customer, null), var.customer)}/${coalesce(try(eb_config.team, null), var.team)}/EventBridge/TriggeredRules/triggered-rules-above-100-per-minute"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "TriggeredRules"
          namespace = "AWS/Events"
          period = 300
          statistic = "Sum"
          threshold = 100
          alarm_description = "EventBridge rule triggered more than 100 times per minute"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "TriggeredRules"
          error_details = "triggered-rules-above-100-per-minute"
        }
      } : "${eb_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "RuleName"
          value = eb_config.name
        }]
      })
    }
  ]...)
}
