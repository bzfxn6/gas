variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "step_function_name" {
  description = "Name of the Step Function"
  type        = string
  default     = "batch-processing-workflow"
}

variable "lambda_functions" {
  description = "List of Lambda function names for batch processing workflow"
  type        = list(string)
  default     = [
    "scm-batch-processor-read-s3",           # [0] Initialize
    "scm-batch-processor-validate-data",     # [1] Validate data
    "scm-batch-processor-calculate-chunks",  # [2] Calculate chunks
    "scm-batch-processor-update-records",    # [3] Process chunks
    "scm-batch-processor-aggregate-results", # [4] Aggregate results
    "scm-batch-processor-send-to-kafka",     # [5] Send to Kafka
    "scm-batch-processor-send-to-sqs-core"   # [6] Send to SQS
  ]
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket containing the data"
  type        = string
}

# Batch Processing Configuration
variable "batch_processing_threshold" {
  description = "Number of records above which to use AWS Batch instead of Lambda"
  type        = number
  default     = 290000  # 290K records - use AWS Batch for chunks > 290K, Lambda for smaller chunks
}

variable "max_records_per_chunk" {
  description = "Maximum number of records to process in each chunk"
  type        = number
  default     = 150000  # Reduced from 200K to 150K for more chunks and better parallelization
}

variable "max_concurrent_chunks" {
  description = "Maximum number of chunks to process in parallel"
  type        = number
  default     = 200  # Increased from 100 to 200 for better parallelization
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 900  # 15 minutes
}

variable "lambda_memory" {
  description = "Memory allocated to Lambda functions in MB"
  type        = number
  default     = 10240  # 10GB max
}

variable "estimated_processing_time_per_record" {
  description = "Estimated processing time per record in seconds"
  type        = number
  default     = 0.005  # 5ms per record (optimized)
}

variable "estimated_memory_per_record" {
  description = "Estimated memory per record in KB"
  type        = number
  default     = 0.5  # 0.5KB per record (optimized)
}

# Performance Optimization
variable "chunk_overlap_percentage" {
  description = "Percentage of overlap between chunks to ensure no records are missed"
  type        = number
  default     = 0.1  # 10% overlap
}

variable "progress_reporting_interval" {
  description = "Interval for progress reporting in seconds"
  type        = number
  default     = 30
}

variable "retry_attempts" {
  description = "Number of retry attempts for failed operations"
  type        = number
  default     = 3
}

variable "retry_backoff_seconds" {
  description = "Backoff time between retries in seconds"
  type        = number
  default     = 60
}

# Kafka and SQS Configuration
variable "kafka_brokers" {
  description = "Kafka broker endpoints"
  type        = string
  default     = ""
}

variable "kafka_topic" {
  description = "Kafka topic name"
  type        = string
  default     = "processed-records"
}

variable "sqs_core_queue_url" {
  description = "SQS Core queue URL"
  type        = string
  default     = ""
}

variable "record_destination" {
  description = "Destination for processed records (kafka or sqs_core)"
  type        = string
  default     = "kafka"
}
  
  # Calculate optimal chunk size based on concurrent processing
  optimal_chunk_size = ceil(60000000 / var.max_concurrent_chunks)
} 