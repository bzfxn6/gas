# Alarm Naming Convention Helper Functions
# This file provides functions to generate standardized alarm names

locals {
  # Helper function to generate alarm name with convention
  # Format: {severity}/{customer}/{team}/{aws-service}/{sub-service}/{error-details}
  generate_alarm_name = {
    # Database alarms
    database_cpu_utilization = (config) => "${var.severity_levels.medium}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/RDS/CPU/cpu-utilization-above-80%"
    database_memory_utilization = (config) => "${var.severity_levels.high}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/RDS/Memory/freeable-memory-below-1gb"
    database_connections = (config) => "${var.severity_levels.medium}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/RDS/Connections/database-connections-above-80"
    database_read_latency = (config) => "${var.severity_levels.medium}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/RDS/Latency/read-latency-above-1s"
    database_write_latency = (config) => "${var.severity_levels.medium}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/RDS/Latency/write-latency-above-1s"
    
    # Lambda alarms
    lambda_errors = (config) => "${var.severity_levels.high}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/Lambda/Errors/function-errors-occurring"
    lambda_duration = (config) => "${var.severity_levels.medium}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/Lambda/Duration/execution-duration-above-30s"
    lambda_throttles = (config) => "${var.severity_levels.medium}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/Lambda/Throttles/function-throttled"
    lambda_concurrent_executions = (config) => "${var.severity_levels.low}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/Lambda/Concurrency/concurrent-executions-above-1000"
    
    # SQS alarms
    sqs_queue_depth = (config) => "${var.severity_levels.medium}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/SQS/QueueDepth/visible-messages-above-100"
    sqs_message_age = (config) => "${var.severity_levels.high}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/SQS/MessageAge/messages-older-than-5min"
    sqs_error_rate = (config) => "${var.severity_levels.high}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/SQS/Errors/error-rate-above-5%"
    
    # ECS alarms
    ecs_cpu_utilization = (config) => "${var.severity_levels.medium}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/ECS/CPU/cpu-utilization-above-80%"
    ecs_memory_utilization = (config) => "${var.severity_levels.medium}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/ECS/Memory/memory-utilization-above-80%"
    ecs_running_task_count = (config) => "${var.severity_levels.high}/${coalesce(config.customer, var.customer)}/${coalesce(config.team, var.team)}/ECS/Tasks/running-tasks-below-1"
  }
}
