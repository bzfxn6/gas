# Base Monitoring Template
# This template provides default monitoring for common AWS resources

# Convert single items to maps for consistent processing
locals {
  # Convert single database to map format
  single_database_map = var.default_monitoring.database != null ? {
    "single-database" = var.default_monitoring.database
  } : {}
  
  # Convert single lambda to map format
  single_lambda_map = var.default_monitoring.lambda != null ? {
    "single-lambda" = var.default_monitoring.lambda
  } : {}
  
  # Convert single SQS queue to map format
  single_sqs_map = var.default_monitoring.sqs_queue != null ? {
    "single-sqs-queue" = var.default_monitoring.sqs_queue
  } : {}
  
  # Convert single ECS service to map format
  single_ecs_map = var.default_monitoring.ecs_service != null ? {
    "single-ecs-service" = var.default_monitoring.ecs_service
  } : {}
  
  # Merge single items with maps
  all_databases = merge(local.single_database_map, var.default_monitoring.databases)
  all_lambdas = merge(local.single_lambda_map, var.default_monitoring.lambdas)
  all_sqs_queues = merge(local.single_sqs_map, var.default_monitoring.sqs_queues)
  all_ecs_services = merge(local.single_ecs_map, var.default_monitoring.ecs_services)
}

# Default database monitoring configuration
locals {
  default_database_alarms = {
    cpu_utilization = {
      alarm_name          = "database-cpu-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/RDS"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "Database CPU utilization is above 80%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
    memory_utilization = {
      alarm_name          = "database-memory-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "FreeableMemory"
      namespace           = "AWS/RDS"
      period              = 300
      statistic           = "Average"
      threshold           = 1073741824  # 1GB in bytes
      alarm_description   = "Database freeable memory is below 1GB"
      treat_missing_data = "notBreaching"
      unit                = "Bytes"
    }
    database_connections = {
      alarm_name          = "database-connections"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "DatabaseConnections"
      namespace           = "AWS/RDS"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "Database has more than 80 connections"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    read_latency = {
      alarm_name          = "database-read-latency"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ReadLatency"
      namespace           = "AWS/RDS"
      period              = 300
      statistic           = "Average"
      threshold           = 1
      alarm_description   = "Database read latency is above 1 second"
      treat_missing_data = "notBreaching"
      unit                = "Seconds"
    }
    write_latency = {
      alarm_name          = "database-write-latency"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "WriteLatency"
      namespace           = "AWS/RDS"
      period              = 300
      statistic           = "Average"
      threshold           = 1
      alarm_description   = "Database write latency is above 1 second"
      treat_missing_data = "notBreaching"
      unit                = "Seconds"
    }
  }
}

# Generate alarms for databases
locals {
  database_alarms = merge([
    for db_key, db_config in local.all_databases : {
      for alarm_key, alarm_config in local.default_database_alarms : "${db_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${db_config.name}-${alarm_config.alarm_name}"
        dimensions = [
          {
            name  = "DBInstanceIdentifier"
            value = db_config.name
          }
        ]
      })
      # Filter alarms based on user selection
      if length(db_config.alarms) == 0 || contains(db_config.alarms, alarm_key)
      # Exclude alarms if specified
      if !contains(coalesce(db_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}

# Generate default dashboard widgets for databases
locals {
  default_database_widgets = [
    for db_key, db_config in local.all_databases : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", db_config.name],
          [".", "FreeableMemory", ".", "."],
          [".", "DatabaseConnections", ".", "."],
          [".", "ReadLatency", ".", "."],
          [".", "WriteLatency", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${db_config.name} Database Metrics"
      }
    }
  ]
}

# Default Lambda monitoring configuration
locals {
  default_lambda_alarms = {
    errors = {
      alarm_name          = "lambda-errors"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "Errors"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "Lambda function has errors"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    duration = {
      alarm_name          = "lambda-duration"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "Duration"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Average"
      threshold           = 30000  # 30 seconds in milliseconds
      alarm_description   = "Lambda function duration is above 30 seconds"
      treat_missing_data = "notBreaching"
      unit                = "Milliseconds"
    }
    throttles = {
      alarm_name          = "lambda-throttles"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "Throttles"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
      alarm_description   = "Lambda function is being throttled"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    concurrent_executions = {
      alarm_name          = "lambda-concurrent-executions"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ConcurrentExecutions"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Average"
      threshold           = 100
      alarm_description   = "Lambda function has more than 100 concurrent executions"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
  }
}

# Generate alarms for Lambda functions
locals {
  lambda_alarms = merge([
    for lambda_key, lambda_config in local.all_lambdas : {
      for alarm_key, alarm_config in local.default_lambda_alarms : "${lambda_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${lambda_config.name}-${alarm_config.alarm_name}"
        dimensions = [
          {
            name  = "FunctionName"
            value = lambda_config.name
          }
        ]
      })
      # Filter alarms based on user selection
      if length(lambda_config.alarms) == 0 || contains(lambda_config.alarms, alarm_key)
      # Exclude alarms if specified
      if !contains(coalesce(lambda_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}

# Generate default dashboard widgets for Lambda functions
locals {
  default_lambda_widgets = [
    for lambda_key, lambda_config in local.all_lambdas : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/Lambda", "Invocations", "FunctionName", lambda_config.name],
          [".", "Errors", ".", "."],
          [".", "Duration", ".", "."],
          [".", "Throttles", ".", "."],
          [".", "ConcurrentExecutions", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${lambda_config.name} Lambda Metrics"
      }
    }
  ]
}

# Default SQS monitoring configuration
locals {
  default_sqs_alarms = {
    queue_depth = {
      alarm_name          = "sqs-queue-depth"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ApproximateNumberOfVisibleMessages"
      namespace           = "AWS/SQS"
      period              = 300
      statistic           = "Average"
      threshold           = 1000
      alarm_description   = "SQS queue has more than 1000 visible messages"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
    message_age = {
      alarm_name          = "sqs-message-age"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "ApproximateAgeOfOldestMessage"
      namespace           = "AWS/SQS"
      period              = 300
      statistic           = "Average"
      threshold           = 300  # 5 minutes in seconds
      alarm_description   = "SQS queue has messages older than 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Seconds"
    }
    error_rate = {
      alarm_name          = "sqs-error-rate"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "NumberOfMessagesSent"
      namespace           = "AWS/SQS"
      period              = 300
      statistic           = "Sum"
      threshold           = 100
      alarm_description   = "SQS queue has more than 100 messages sent per 5 minutes"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
  }
}

# Generate alarms for SQS queues
locals {
  sqs_alarms = merge([
    for sqs_key, sqs_config in local.all_sqs_queues : {
      for alarm_key, alarm_config in local.default_sqs_alarms : "${sqs_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${sqs_config.name}-${alarm_config.alarm_name}"
        dimensions = [
          {
            name  = "QueueName"
            value = sqs_config.name
          }
        ]
      })
      # Filter alarms based on user selection
      if length(sqs_config.alarms) == 0 || contains(sqs_config.alarms, alarm_key)
      # Exclude alarms if specified
      if !contains(coalesce(sqs_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}

# Generate default dashboard widgets for SQS queues
locals {
  default_sqs_widgets = [
    for sqs_key, sqs_config in local.all_sqs_queues : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/SQS", "ApproximateNumberOfVisibleMessages", "QueueName", sqs_config.name],
          [".", "ApproximateAgeOfOldestMessage", ".", "."],
          [".", "NumberOfMessagesSent", ".", "."],
          [".", "NumberOfMessagesReceived", ".", "."]
        ]
        period = 300
        stat   = "Sum"
        region = var.region
        title  = "${sqs_config.name} SQS Queue Metrics"
      }
    }
  ]
}

# Default ECS monitoring configuration
locals {
  default_ecs_alarms = {
    cpu_utilization = {
      alarm_name          = "ecs-cpu-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "ECS service CPU utilization is above 80%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
    memory_utilization = {
      alarm_name          = "ecs-memory-utilization"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "MemoryUtilization"
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "ECS service memory utilization is above 80%"
      treat_missing_data = "notBreaching"
      unit                = "Percent"
    }
    running_task_count = {
      alarm_name          = "ecs-running-task-count"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 1
      metric_name         = "RunningTaskCount"
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      threshold           = 1
      alarm_description   = "ECS service has no running tasks"
      treat_missing_data = "notBreaching"
      unit                = "Count"
    }
  }
}

# Generate alarms for ECS services
locals {
  ecs_alarms = merge([
    for ecs_key, ecs_config in local.all_ecs_services : {
      for alarm_key, alarm_config in local.default_ecs_alarms : "${ecs_key}-${alarm_key}" => merge(alarm_config, {
        alarm_name = "${ecs_config.name}-${alarm_config.alarm_name}"
        dimensions = [
          {
            name  = "ServiceName"
            value = ecs_config.name
          },
          {
            name  = "ClusterName"
            value = ecs_config.cluster_name
          }
        ]
      })
      # Filter alarms based on user selection
      if length(ecs_config.alarms) == 0 || contains(ecs_config.alarms, alarm_key)
      # Exclude alarms if specified
      if !contains(coalesce(ecs_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}

# Generate default dashboard widgets for ECS services
locals {
  default_ecs_widgets = [
    for ecs_key, ecs_config in local.all_ecs_services : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/ECS", "CPUUtilization", "ServiceName", ecs_config.name, "ClusterName", ecs_config.cluster_name],
          [".", "MemoryUtilization", ".", ".", ".", "."],
          [".", "RunningTaskCount", ".", ".", ".", "."],
          [".", "DesiredTaskCount", ".", ".", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = var.region
        title  = "${ecs_config.name} ECS Service Metrics"
      }
    }
  ]
}
