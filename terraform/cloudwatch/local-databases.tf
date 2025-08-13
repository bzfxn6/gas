# Database Monitoring Locals
# This file contains all database-related alarm definitions

locals {
  # Generate database alarms with dynamic naming
  database_alarms = merge([
    for db_key, db_config in local.all_databases : {
      for alarm_key, alarm_config in {
        cpu_utilization = {
          alarm_name = "Sev2/${coalesce(try(db_config.customer, null), var.customer)}/${coalesce(try(db_config.team, null), var.team)}/RDS/CPU/cpu-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "CPUUtilization"
          namespace = "AWS/RDS"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "Database CPU utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          severity = "Sev2"
          sub_service = "CPU"
          error_details = "cpu-utilization-above-80pct"
        }
        memory_utilization = {
          alarm_name = "Sev2/${coalesce(try(db_config.customer, null), var.customer)}/${coalesce(try(db_config.team, null), var.team)}/RDS/Memory/memory-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "FreeableMemory"
          namespace = "AWS/RDS"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "Database memory utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Bytes"
          severity = "Sev2"
          sub_service = "Memory"
          error_details = "memory-utilization-above-80pct"
        }
        database_connections = {
          alarm_name = "Sev2/${coalesce(try(db_config.customer, null), var.customer)}/${coalesce(try(db_config.team, null), var.team)}/RDS/Connections/database-connections-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "DatabaseConnections"
          namespace = "AWS/RDS"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "Database connections are above 80%"
          treat_missing_data = "notBreaching"
          unit = "Count"
          severity = "Sev2"
          sub_service = "Connections"
          error_details = "database-connections-above-80pct"
        }
      } : "${db_key}-${alarm_key}" => merge(alarm_config, {
        dimensions = [{
          name = "DBInstanceIdentifier"
          value = db_config.name
        }]
      })
    }
  ]...)
}

