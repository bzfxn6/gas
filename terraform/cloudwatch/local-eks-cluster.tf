# EKS Cluster Monitoring Template
# This template provides default monitoring for EKS clusters with short_name support
# Supports simple overrides via alarm_overrides in JSON configuration

# Generate alarms for EKS clusters with short_name support
locals {
  eks_cluster_alarms = merge([
    for eks_key, eks_config in local.all_eks_clusters : {
      for alarm_key, alarm_config in {
        # Define default alarm configurations with merge support for overrides
        cpu_utilization = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/CPU/cpu-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "node_cpu_utilization"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "EKS cluster CPU utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.cpu_utilization, {}))
        
        memory_utilization = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Memory/memory-utilization-above-80pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "node_memory_utilization"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Average"
          threshold = 80
          alarm_description = "EKS cluster memory utilization is above 80%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.memory_utilization, {}))
        
        disk_utilization = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Disk/disk-utilization-above-85pct"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "node_filesystem_utilization"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Average"
          threshold = 85
          alarm_description = "EKS cluster disk utilization is above 85%"
          treat_missing_data = "notBreaching"
          unit = "Percent"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.disk_utilization, {}))
        
        failed_node_count = merge({
          alarm_name = "Sev1/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Nodes/failed-node-count-above-0"
          comparison_operator = "GreaterThanOrEqualToThreshold"
          evaluation_periods = 1
          metric_name = "cluster_failed_node_count"
          namespace = "ContainerInsights"
          period = 300
          statistic = "Average"
          threshold = 1
          alarm_description = "EKS cluster has 1 or more failed nodes"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.failed_node_count, {}))
        
        # EKS API Server Metrics
        apiserver_request_total_4xx = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/4xx-requests-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_request_total_4XX"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 10
          alarm_description = "EKS API server 4XX requests are above threshold"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_total_4xx, {}))
        
        apiserver_request_total_5xx = merge({
          alarm_name = "Sev1/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/5xx-requests-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 1
          metric_name = "apiserver_request_total_5XX"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 1
          alarm_description = "EKS API server 5XX requests are above threshold"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_total_5xx, {}))
        
        apiserver_request_total_429 = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/429-requests-above-threshold"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_request_total_429"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 5
          alarm_description = "EKS API server 429 rate limit requests are above threshold"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_total_429, {}))
        
        # Scheduler Metrics
        scheduler_pending_pods = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Scheduler/pending-pods-above-10"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "scheduler_pending_pods"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 10
          alarm_description = "EKS scheduler has more than 10 pending pods"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.scheduler_pending_pods, {}))
        
        scheduler_pending_pods_unschedulable = merge({
          alarm_name = "Sev1/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Scheduler/unschedulable-pods-above-5"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "scheduler_pending_pods_UNSCHEDULABLE"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 5
          alarm_description = "EKS scheduler has more than 5 unschedulable pods"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.scheduler_pending_pods_unschedulable, {}))
        
        # API Server Performance Metrics
        apiserver_request_duration_seconds_get_p99 = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/get-request-duration-above-1s"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_request_duration_seconds_GET_P99"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 1
          alarm_description = "EKS API server GET request duration P99 is above 1 second"
          treat_missing_data = "notBreaching"
          unit = "Seconds"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_duration_seconds_get_p99, {}))
        
        apiserver_request_duration_seconds_put_p99 = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/put-request-duration-above-1s"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_request_duration_seconds_PUT_P99"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 1
          alarm_description = "EKS API server PUT request duration P99 is above 1 second"
          treat_missing_data = "notBreaching"
          unit = "Seconds"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_duration_seconds_put_p99, {}))
        
        apiserver_request_duration_seconds_delete_p99 = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/delete-request-duration-above-1s"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_request_duration_seconds_DELETE_P99"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 1
          alarm_description = "EKS API server DELETE request duration P99 is above 1 second"
          treat_missing_data = "notBreaching"
          unit = "Seconds"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_duration_seconds_delete_p99, {}))
        
        apiserver_request_duration_seconds_list_p99 = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/list-request-duration-above-1s"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_request_duration_seconds_LIST_P99"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 1
          alarm_description = "EKS API server LIST request duration P99 is above 1 second"
          treat_missing_data = "notBreaching"
          unit = "Seconds"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_duration_seconds_list_p99, {}))
        
        apiserver_request_duration_seconds_patch_p99 = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/patch-request-duration-above-1s"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_request_duration_seconds_PATCH_P99"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 1
          alarm_description = "EKS API server PATCH request duration P99 is above 1 second"
          treat_missing_data = "notBreaching"
          unit = "Seconds"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_duration_seconds_patch_p99, {}))
        
        apiserver_request_duration_seconds_post_p99 = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/post-request-duration-above-1s"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_request_duration_seconds_POST_P99"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 1
          alarm_description = "EKS API server POST request duration P99 is above 1 second"
          treat_missing_data = "notBreaching"
          unit = "Seconds"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_duration_seconds_post_p99, {}))
        
        apiserver_current_inflight_requests = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/inflight-requests-above-100"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_current_inflight_requests_READONLY"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 100
          alarm_description = "EKS API server has more than 100 inflight readonly requests"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_current_inflight_requests, {}))
        
        apiserver_current_inflight_requests_mutating = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/inflight-mutating-requests-above-50"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_current_inflight_requests_MUTATING"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 50
          alarm_description = "EKS API server has more than 50 inflight mutating requests"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_current_inflight_requests_mutating, {}))
        
        # Additional Scheduler Metrics
        scheduler_pending_pods_backoff = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Scheduler/pending-pods-backoff-above-5"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "scheduler_pending_pods_BACKOFF"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 5
          alarm_description = "EKS scheduler has more than 5 pending pods in backoff"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.scheduler_pending_pods_backoff, {}))
        
        scheduler_pending_pods_gated = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Scheduler/pending-pods-gated-above-5"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "scheduler_pending_pods_GATED"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 5
          alarm_description = "EKS scheduler has more than 5 pending pods gated"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.scheduler_pending_pods_gated, {}))
        
        scheduler_pending_pods_activeq = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Scheduler/pending-pods-activeq-above-10"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "scheduler_pending_pods_ACTIVEQ"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 10
          alarm_description = "EKS scheduler has more than 10 pending pods in active queue"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.scheduler_pending_pods_activeq, {}))
        
        scheduler_schedule_attempts_error = merge({
          alarm_name = "Sev1/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Scheduler/schedule-attempts-error-above-5"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "scheduler_schedule_attempts_ERROR"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 5
          alarm_description = "EKS scheduler has more than 5 schedule attempt errors"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.scheduler_schedule_attempts_error, {}))
        
        scheduler_schedule_attempts_scheduled = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Scheduler/schedule-attempts-scheduled-below-10"
          comparison_operator = "LessThanThreshold"
          evaluation_periods = 2
          metric_name = "scheduler_schedule_attempts_SCHEDULED"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 10
          alarm_description = "EKS scheduler has less than 10 successful schedule attempts"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.scheduler_schedule_attempts_scheduled, {}))
        
        scheduler_schedule_attempts_unschedulable = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Scheduler/schedule-attempts-unschedulable-above-5"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "scheduler_schedule_attempts_UNSCHEDULABLE"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 5
          alarm_description = "EKS scheduler has more than 5 unschedulable schedule attempts"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.scheduler_schedule_attempts_unschedulable, {}))
        
        scheduler_schedule_attempts_total = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/Scheduler/schedule-attempts-total-below-10"
          comparison_operator = "LessThanThreshold"
          evaluation_periods = 2
          metric_name = "scheduler_schedule_attempts_total"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 10
          alarm_description = "EKS scheduler has less than 10 total schedule attempts"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.scheduler_schedule_attempts_total, {}))
        
        # Admission Webhook Metrics
        apiserver_admission_webhook_rejection_count_admit = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/admission-webhook-rejection-admit-above-5"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_admission_webhook_rejection_count_ADMIT"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 5
          alarm_description = "EKS API server admission webhook rejection count for ADMIT is above 5"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_admission_webhook_rejection_count_admit, {}))
        
        apiserver_admission_webhook_rejection_count_validating = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/admission-webhook-rejection-validating-above-5"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_admission_webhook_rejection_count_VALIDATING"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 5
          alarm_description = "EKS API server admission webhook rejection count for VALIDATING is above 5"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_admission_webhook_rejection_count_validating, {}))
        
        apiserver_admission_webhook_request_total_validating = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/admission-webhook-request-validating-above-100"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_admission_webhook_request_total_VALIDATING"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 100
          alarm_description = "EKS API server admission webhook request total for VALIDATING is above 100"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_admission_webhook_request_total_validating, {}))
        
        apiserver_admission_webhook_request_total_admit = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/admission-webhook-request-admit-above-100"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_admission_webhook_request_total_ADMIT"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 100
          alarm_description = "EKS API server admission webhook request total for ADMIT is above 100"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_admission_webhook_request_total_admit, {}))
        
        apiserver_admission_webhook_request_total = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/admission-webhook-request-total-above-200"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_admission_webhook_request_total"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 200
          alarm_description = "EKS API server admission webhook request total is above 200"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_admission_webhook_request_total, {}))
        
        # Storage and Request Metrics
        apiserver_storage_size_bytes = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/storage-size-above-1gb"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_storage_size_bytes"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Average"
          threshold = 1073741824  # 1GB in bytes
          alarm_description = "EKS API server storage size is above 1GB"
          treat_missing_data = "notBreaching"
          unit = "Bytes"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_storage_size_bytes, {}))
        
        apiserver_request_total = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/request-total-above-1000"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_request_total"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 1000
          alarm_description = "EKS API server total requests are above 1000"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_total, {}))
        
        apiserver_request_total_list_pods = merge({
          alarm_name = "Sev2/${coalesce(try(eks_config.customer, null), var.customer)}/${coalesce(try(eks_config.team, null), var.team)}/EKS${try(eks_config.short_name, "") != "" ? "-${eks_config.short_name}" : ""}/Cluster/APIServer/request-total-list-pods-above-100"
          comparison_operator = "GreaterThanThreshold"
          evaluation_periods = 2
          metric_name = "apiserver_request_total_LIST_PODS"
          namespace = "AWS/EKS"
          period = 300
          statistic = "Sum"
          threshold = 100
          alarm_description = "EKS API server LIST_PODS requests are above 100"
          treat_missing_data = "notBreaching"
          unit = "Count"
          dimensions = [{ name = "ClusterName", value = eks_config.name }]
        }, try(eks_config.alarm_overrides.apiserver_request_total_list_pods, {}))
        


      } : "${eks_key}-${alarm_key}" => alarm_config
      if (length(try(eks_config.alarms, [])) == 0 || contains(try(eks_config.alarms, []), alarm_key)) && !contains(try(eks_config.exclude_alarms, []), alarm_key)
    }
  ]...)
}
