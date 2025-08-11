# Selective Alarm Selection Example
# This example shows how to choose specific alarms from templates

module "cloudwatch" {
  source = "../../terraform/cloudwatch"
  
  region = "us-east-1"
  environment = "production"
  project = "my-app"
  
  default_monitoring = {
    # Single database with selective alarms
    database = {
      name = "main-database"
      # Only include CPU and memory monitoring, skip latency
      alarms = ["cpu_utilization", "memory_utilization", "database_connections"]
      # Or exclude specific alarms
      # exclude_alarms = ["read_latency", "write_latency"]
    }
    
    # Multiple databases with different alarm selections
    databases = {
      read-replica = {
        name = "read-replica-database"
        # Only monitor connections and latency for read replicas
        alarms = ["database_connections", "read_latency"]
      }
      
      analytics-db = {
        name = "analytics-database"
        # Monitor everything except write latency (read-only workload)
        exclude_alarms = ["write_latency"]
      }
    }
    
    # Lambda functions with selective monitoring
    lambdas = {
      api-function = {
        name = "api-lambda"
        # Only monitor errors and duration for API functions
        alarms = ["errors", "duration"]
      }
      
      batch-processor = {
        name = "batch-processor-lambda"
        # Monitor everything except concurrent executions
        exclude_alarms = ["concurrent_executions"]
      }
    }
    
    # EC2 instances with selective monitoring
    ec2_instances = {
      web-server = {
        name = "web-server"
        # Only monitor CPU, network, and status checks
        alarms = ["cpu_utilization", "network_in", "network_out", "status_check_failed"]
        # Skip disk and EBS monitoring for web servers
        exclude_alarms = ["disk_read_bytes", "disk_write_bytes", "ebs_read_bytes", "ebs_write_bytes"]
      }
      
      database-server = {
        name = "database-server"
        # Monitor everything for database servers
        # (no alarms specified = all alarms included)
      }
      
      batch-processor = {
        name = "batch-processor"
        # Only monitor CPU and memory for batch processors
        alarms = ["cpu_utilization", "cpu_credit_balance", "memory_utilization"]
      }
    }
    
    # S3 buckets with selective monitoring
    s3_buckets = {
      application-data = {
        name = "application-data-bucket"
        # Only monitor capacity and errors
        alarms = ["bucket_size_bytes", "number_of_objects", "errors_4xx", "errors_5xx"]
      }
      
      backup-storage = {
        name = "backup-storage-bucket"
        # Monitor everything except performance metrics
        exclude_alarms = ["first_byte_latency", "total_request_latency"]
      }
      
      user-uploads = {
        name = "user-uploads-bucket"
        # Only monitor request counts and data transfer
        alarms = ["all_requests", "get_requests", "put_requests", "bytes_downloaded", "bytes_uploaded"]
      }
    }
    
    # EKS clusters with selective monitoring
    eks_clusters = {
      production-cluster = {
        name = "production-eks-cluster"
        # Monitor everything for production
      }
      
      staging-cluster = {
        name = "staging-eks-cluster"
        # Only monitor basic metrics for staging
        alarms = ["cluster_cpu_utilization", "cluster_memory_utilization", "cluster_node_count"]
      }
    }
    
    # EKS pods with selective monitoring
    eks_pods = {
      web-app-pod = {
        name = "web-app-pod"
        namespace = "web"
        cluster_name = "production-eks-cluster"
        # Only monitor CPU and memory for web apps
        alarms = ["pod_cpu_utilization", "pod_memory_utilization"]
      }
      
      database-pod = {
        name = "database-pod"
        namespace = "database"
        cluster_name = "production-eks-cluster"
        # Monitor everything for database pods
      }
    }
    
    # Step Functions with selective monitoring
    step_functions = {
      order-processing = {
        name = "order-processing-workflow"
        # Only monitor execution success/failure and time
        alarms = ["execution_success_rate", "execution_failure_rate", "execution_time"]
      }
      
      data-pipeline = {
        name = "data-pipeline-workflow"
        # Monitor everything except activity metrics
        exclude_alarms = ["activity_failed", "activity_succeeded", "activity_time"]
      }
    }
  }
  
  common_tags = {
    Environment = "production"
    Project     = "my-app"
    ManagedBy   = "terraform"
  }
}
