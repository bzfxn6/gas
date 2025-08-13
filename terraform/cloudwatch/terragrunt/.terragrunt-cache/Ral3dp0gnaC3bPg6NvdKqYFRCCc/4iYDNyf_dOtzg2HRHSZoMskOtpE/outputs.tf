# Local value outputs for debugging and information
output "all_alarms" {
  description = "All alarms that would be created (local values)"
  value       = local.all_alarms
}

output "alarm_count" {
  description = "Number of alarms that would be created"
  value       = length(local.all_alarms)
}

output "alarm_names" {
  description = "Names of alarms that would be created"
  value       = [for k, v in local.all_alarms : v.alarm_name]
}

output "database_alarms" {
  description = "Database alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-cpu_utilization$|.*-memory_utilization$|.*-database_connections$", k)) }
}

output "eks_alarms" {
  description = "EKS cluster alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-cpu_utilization$|.*-memory_utilization$|.*-disk_utilization$|.*-pod_count$|.*-node_count$|.*-network_receive$|.*-network_transmit$", k)) }
}

output "lambda_alarms" {
  description = "Lambda alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-errors$|.*-duration$|.*-throttles$", k)) }
}

output "sqs_alarms" {
  description = "SQS alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-queue_depth$", k)) }
}

output "resource_summary" {
  description = "Summary of resources that would be created"
  value = {
    total_alarms = length(local.all_alarms)
    databases    = length(local.all_databases)
    lambdas      = length(local.all_lambdas)
    sqs_queues   = length(local.all_sqs_queues)
    eks_clusters = length(local.all_eks_clusters)
    ecs_services = length(local.all_ecs_services)
    eks_pods     = length(local.all_eks_pods)
    eks_nodegroups = length(local.all_eks_nodegroups)
    step_functions = length(local.all_step_functions)
    ec2_instances = length(local.all_ec2_instances)
    s3_buckets   = length(local.all_s3_buckets)
    eventbridge_rules = length(local.all_eventbridge_rules)
    log_alarms   = length(local.all_log_alarms)
  }
} 