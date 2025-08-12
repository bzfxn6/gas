# EventBridge Monitoring Template
# This template provides default monitoring for AWS EventBridge

# Default EventBridge monitoring configuration
locals {
  eventbridge_alarms = {
    failed_invocations = {
      alarm_name          = "eventbridge-failed-invocations"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "FailedInvocations"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EventBridge has failed invocations"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    dead_letter_invocations = {
      alarm_name          = "eventbridge-dead-letter-invocations"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "DeadLetterInvocations"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EventBridge has dead letter invocations"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    throttled_rules = {
      alarm_name          = "eventbridge-throttled-rules"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "ThrottledRules"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EventBridge rules are being throttled"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    triggered_rules = {
      alarm_name          = "eventbridge-triggered-rules"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "TriggeredRules"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000
      alarm_description   = "EventBridge has more than 1000 triggered rules per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    invocations = {
      alarm_name          = "eventbridge-invocations"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "Invocations"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000
      alarm_description   = "EventBridge has more than 1000 invocations per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    delivery_failed = {
      alarm_name          = "eventbridge-delivery-failed"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "DeliveryFailed"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EventBridge event delivery has failed"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    delivery_duration = {
      alarm_name          = "eventbridge-delivery-duration"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "DeliveryDuration"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Average"
      threshold           = 5000  # 5 seconds in milliseconds
      alarm_description   = "EventBridge event delivery duration is above 5 seconds"
      treat_missing_data = "notBreaching"
      unit                = "Milliseconds"
    }
    target_errors = {
      alarm_name          = "eventbridge-target-errors"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "TargetErrors"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EventBridge target errors have occurred"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    target_duration = {
      alarm_name          = "eventbridge-target-duration"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "TargetDuration"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Average"
      threshold           = 30000  # 30 seconds in milliseconds
      alarm_description   = "EventBridge target duration is above 30 seconds"
      treat_missing_data = "notBreaching"
      unit                = "Milliseconds"
    }
    sent_events = {
      alarm_name          = "eventbridge-sent-events"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "SentEvents"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000
      alarm_description   = "EventBridge has sent more than 1000 events per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    received_events = {
      alarm_name          = "eventbridge-received-events"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ReceivedEvents"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 1000
      alarm_description   = "EventBridge has received more than 1000 events per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    dropped_events = {
      alarm_name          = "eventbridge-dropped-events"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "DroppedEvents"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EventBridge has dropped events"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    replay_failed = {
      alarm_name          = "eventbridge-replay-failed"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "ReplayFailed"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EventBridge replay has failed"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    replay_canceled = {
      alarm_name          = "eventbridge-replay-canceled"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "ReplayCanceled"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "EventBridge replay has been canceled"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    replay_events = {
      alarm_name          = "eventbridge-replay-events"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ReplayEvents"
      namespace           = "AWS/Events"
      period              = 300
      statistic           = "Sum"
      threshold           = 100
      alarm_description   = "EventBridge has more than 100 replay events per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
  }
}

# Generate alarms for EventBridge rules
locals {
  eventbridge_monitoring = merge([
    for eb_key, eb_config in local.all_eventbridge_rules : {
      for alarm_key, alarm_config in local.eventbridge_alarms : "${eb_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${eb_config.name}-${alarm_config.alarm_name}"
        dimensions = [
          {
            name  = "RuleName"
            value = eb_config.name
          }
        ]
      })
      # Filter alarms based on user selection
      if length(eb_config.alarms) == 0 || contains(eb_config.alarms, alarm_key)
      # Exclude alarms if specified
      if !contains(coalesce(eb_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}

# Generate default dashboard widgets for EventBridge rules
locals {
  eventbridge_dashboard_widgets = [
    for eb_key, eb_config in local.all_eventbridge_rules : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/Events", "TriggeredRules", "RuleName", eb_config.name],
          [".", "Invocations", ".", "."],
          [".", "FailedInvocations", ".", "."],
          [".", "DeadLetterInvocations", ".", "."],
          [".", "ThrottledRules", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${eb_config.name} EventBridge Rule Metrics"
      }
    }
  ]
}

# Generate delivery performance widgets for EventBridge rules
locals {
  eventbridge_delivery_widgets = [
    for eb_key, eb_config in local.all_eventbridge_rules : {
      type   = "metric"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/Events", "DeliveryFailed", "RuleName", eb_config.name],
          [".", "DeliveryDuration", ".", "."],
          [".", "TargetErrors", ".", "."],
          [".", "TargetDuration", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${eb_config.name} EventBridge Delivery Performance"
      }
    }
  ]
}

# Generate event flow widgets for EventBridge rules
locals {
  eventbridge_flow_widgets = [
    for eb_key, eb_config in local.all_eventbridge_rules : {
      type   = "metric"
      x      = 0
      y      = 6
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/Events", "SentEvents", "RuleName", eb_config.name],
          [".", "ReceivedEvents", ".", "."],
          [".", "DroppedEvents", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${eb_config.name} EventBridge Event Flow"
      }
    }
  ]
}

# Generate replay widgets for EventBridge rules
locals {
  eventbridge_replay_widgets = [
    for eb_key, eb_config in local.all_eventbridge_rules : {
      type   = "metric"
      x      = 12
      y      = 6
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/Events", "ReplayEvents", "RuleName", eb_config.name],
          [".", "ReplayFailed", ".", "."],
          [".", "ReplayCanceled", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${eb_config.name} EventBridge Replay Metrics"
      }
    }
  ]
}
