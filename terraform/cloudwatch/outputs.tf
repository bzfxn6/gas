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

output "eks_cluster_alarms" {
  description = "EKS cluster alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-cpu_utilization$|.*-memory_utilization$|.*-disk_utilization$|.*-pod_count$|.*-node_count$|.*-network_receive$|.*-network_transmit$|.*-failed_node_count$", k)) }
}

output "eks_pod_alarms" {
  description = "EKS pod alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-pod_cpu_utilization$|.*-pod_memory_utilization$|.*-pod_network_rx$|.*-pod_network_tx$", k)) }
}

output "eks_service_alarms" {
  description = "EKS service alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-service_number_of_running_pods$|.*-service_number_of_running_pods_total$", k)) }
}

output "eks_volume_alarms" {
  description = "EKS volume alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-volume_used$|.*-volume_total$|.*-volume_available$", k)) }
}

output "eks_node_alarms" {
  description = "EKS node alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-node_cpu_utilization$|.*-node_memory_utilization$|.*-node_disk_utilization$|.*-node_network_rx$|.*-node_network_tx$", k)) }
}

output "eks_asg_alarms" {
  description = "EKS ASG alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-asg.*-status_check_failed$|.*-asg.*-cpu_utilization$|.*-asg.*-memory_utilization$|.*-asg.*-disk_utilization$|.*-asg.*-ebs_read_ops$|.*-asg.*-ebs_write_ops$|.*-asg.*-network_in$|.*-asg.*-network_out$", k)) }
}

output "eks_nodegroup_alarms" {
  description = "EKS nodegroup alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-nodegroup_cpu_utilization$|.*-nodegroup_memory_utilization$|.*-nodegroup_disk_utilization$", k)) }
}

output "lambda_alarms" {
  description = "Lambda alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-errors$|.*-duration$|.*-throttles$", k)) }
}

output "sqs_alarms" {
  description = "SQS alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-queue_depth$", k)) }
}

output "ecs_alarms" {
  description = "ECS alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-cpu_utilization$|.*-memory_utilization$|.*-running_task_count$", k)) }
}

output "ec2_alarms" {
  description = "EC2 alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-cpu_utilization$|.*-memory_utilization$|.*-disk_utilization$|.*-network_in$|.*-network_out$", k)) }
}

output "s3_alarms" {
  description = "S3 alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-bucket_size$|.*-number_of_objects$|.*-all_requests$|.*-get_requests$|.*-put_requests$", k)) }
}

output "step_function_alarms" {
  description = "Step Function alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-executions_failed$|.*-executions_succeeded$|.*-execution_time$", k)) }
}

output "eventbridge_alarms" {
  description = "EventBridge alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-triggered_rules$|.*-invoked_targets$|.*-failed_invocations$", k)) }
}

output "log_alarms" {
  description = "Log alarms that would be created"
  value       = { for k, v in local.all_alarms : k => v if can(regex(".*-error_count$|.*-warning_count$", k)) }
}

output "resource_summary" {
  description = "Summary of resources that would be created"
  value = {
    total_alarms = length(local.all_alarms)
    databases    = length(local.all_databases)
    lambdas      = length(local.all_lambdas)
    sqs_queues   = length(local.all_sqs_queues)
    eks_clusters = length(local.all_eks_clusters)
    eks_pods     = length(local.all_eks_pods)
    eks_services = length(local.all_eks_services)
    eks_volumes  = length(local.all_eks_volumes)
    eks_nodes    = length(local.all_eks_nodes)
    eks_asgs     = length(local.all_eks_asgs)
    eks_nodegroups = length(local.all_eks_nodegroups)
    ecs_services = length(local.all_ecs_services)
    step_functions = length(local.all_step_functions)
    ec2_instances = length(local.all_ec2_instances)
    s3_buckets   = length(local.all_s3_buckets)
    eventbridge_rules = length(local.all_eventbridge_rules)
    log_alarms   = length(local.all_log_alarms)
  }
} 