provider "aws" {
  region = var.aws_region
}

# Step Function IAM Role
resource "aws_iam_role" "step_function_role" {
  name = "step_function_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Step Function to invoke Lambda, SQS, and AWS Batch
resource "aws_iam_role_policy" "step_function_policy" {
  name = "step_function_policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "batch:SubmitJob",
          "batch:DescribeJobs",
          "batch:ListJobs",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          for func in var.lambda_functions :
          "arn:aws:lambda:${var.aws_region}:*:function:${func}",
          "arn:aws:sqs:${var.aws_region}:*:batch-proc",
          "arn:aws:sqs:${var.aws_region}:*:batch-proc-*",
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*",
          "arn:aws:batch:${var.aws_region}:*:job-queue/*",
          "arn:aws:batch:${var.aws_region}:*:job-definition/*",
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/batch/job:*"
        ]
      }
    ]
  })
}

# AWS Batch Job Queue for heavy processing
resource "aws_batch_job_queue" "batch_processing_queue" {
  name     = "${var.step_function_name}-batch-queue"
  state    = "ENABLED"
  priority = 1

  compute_environments = [
    aws_batch_compute_environment.batch_compute.arn
  ]
}

# AWS Batch Compute Environment
resource "aws_batch_compute_environment" "batch_compute" {
  compute_environment_name = "${var.step_function_name}-compute"
  type                    = "MANAGED"
  state                   = "ENABLED"
  service_role            = aws_iam_role.batch_service_role.arn

  compute_resources {
    type                = "EC2"
    maxv_cpus           = var.batch_max_vcpus
    minv_cpus           = var.batch_min_vcpus
    desiredv_cpus       = var.batch_desired_vcpus
    instance_types      = var.batch_instance_types
    subnets             = var.batch_subnet_ids
    security_group_ids  = var.batch_security_group_ids
    instance_role       = aws_iam_role.batch_instance_role.arn
    launch_template {
      launch_template_id = aws_launch_template.batch_launch_template.id
      version            = "$Latest"
    }
  }
}

# IAM Role for AWS Batch Service
resource "aws_iam_role" "batch_service_role" {
  name = "${var.step_function_name}-batch-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# IAM Role for AWS Batch Instances
resource "aws_iam_role" "batch_instance_role" {
  name = "${var.step_function_name}-batch-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_instance_role_policy" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Launch Template for Batch instances
resource "aws_launch_template" "batch_launch_template" {
  name_prefix   = "${var.step_function_name}-batch"
  image_id      = var.batch_ami_id
  instance_type = var.batch_instance_types[0]

  vpc_security_group_ids = var.batch_security_group_ids
  subnet_id              = var.batch_subnet_ids[0]

  iam_instance_profile {
    name = aws_iam_instance_profile.batch_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/batch_user_data.sh", {
    region = var.aws_region
  }))
}

# IAM Instance Profile for Batch instances
resource "aws_iam_instance_profile" "batch_instance_profile" {
  name = "${var.step_function_name}-batch-instance-profile"
  role = aws_iam_role.batch_instance_role.name
}

# AWS Batch Job Definition
resource "aws_batch_job_definition" "batch_processing_job" {
  name = "${var.step_function_name}-batch-job"
  type = "container"

  container_properties = jsonencode({
    image = var.batch_container_image
    vcpus = var.batch_job_vcpus
    memory = var.batch_job_memory
    
    environment = [
      {
        name  = "AWS_REGION"
        value = var.aws_region
      },
      {
        name  = "S3_BUCKET"
        value = var.s3_bucket_name
      }
    ]
    
    mountPoints = []
    volumes = []
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/batch/job"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  })
}

# Step Function Definition with Batch Processing
resource "aws_sfn_state_machine" "example" {
  name     = var.step_function_name
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "A Step Function to process 60M records with batch processing capabilities"
    StartAt = "InitializeBatchProcessing"
    States = {
      InitializeBatchProcessing = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[0]}"
        ResultPath = "$.batchConfig"
        Next = "ValidateBatchConfig"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "ReportFailure"
            ResultPath = "$.errorCause"
          }
        ]
      }
      
      ValidateBatchConfig = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.batchConfig.batchStatus"
            StringMatches = "SUBMISSION_FAILED"
            Next = "ReportFailure"
          }
        ]
        Default = "CalculateChunks"
      }
      
      CalculateChunks = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[1]}"
        InputPath = "$.batchConfig"
        ResultPath = "$.chunkConfig"
        Next = "ProcessChunksInParallel"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "ReportFailure"
            ResultPath = "$.errorCause"
          }
        ]
      }
      
      ProcessChunksInParallel = {
        Type = "Map"
        InputPath = "$.chunkConfig.chunks"
        ItemsPath = "$.chunks"
        MaxConcurrency = var.max_concurrent_chunks
        Iterator = {
          StartAt = "ProcessChunk"
          States = {
            ProcessChunk = {
              Type = "Choice"
              Choices = [
                {
                  Variable = "$.chunkSize"
                  NumericGreaterThan = var.batch_processing_threshold
                  Next = "SubmitBatchJob"
                }
              ]
              Default = "ProcessWithLambda"
            }
            
            ProcessWithLambda = {
              Type = "Task"
              Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[2]}"
              ResultPath = "$.chunkResult"
              Next = "ChunkComplete"
              Catch = [
                {
                  ErrorEquals = ["States.ALL"]
                  Next = "ChunkFailed"
                  ResultPath = "$.chunkError"
                }
              ]
            }
            
            SubmitBatchJob = {
              Type = "Task"
              Resource = "arn:aws:states:::batch:submitJob"
              Parameters = {
                JobName = "batch-chunk-${States.UUID()}"
                JobQueue = aws_batch_job_queue.batch_processing_queue.arn
                JobDefinition = aws_batch_job_definition.batch_processing_job.arn
                Parameters = {
                  "chunkId.$" = "$.chunkId"
                  "startIndex.$" = "$.startIndex"
                  "endIndex.$" = "$.endIndex"
                  "bucket.$" = "$.bucket"
                  "file.$" = "$.file"
                  "customerId.$" = "$.customerId"
                  "tenantId.$" = "$.tenantId"
                  "batchId.$" = "$.batchId"
                }
              }
              ResultPath = "$.batchJob"
              Next = "WaitForBatchJob"
            }
            
            WaitForBatchJob = {
              Type = "Wait"
              Seconds = 30
              Next = "CheckBatchJobStatus"
            }
            
            CheckBatchJobStatus = {
              Type = "Task"
              Resource = "arn:aws:states:::batch:describeJobs"
              Parameters = {
                Jobs = ["${States.Format('{}', $.batchJob.JobId)}"]
              }
              ResultPath = "$.jobStatus"
              Next = "BatchJobComplete"
            }
            
            BatchJobComplete = {
              Type = "Choice"
              Choices = [
                {
                  Variable = "$.jobStatus.Jobs[0].Status"
                  StringEquals = "SUCCEEDED"
                  Next = "ChunkComplete"
                },
                {
                  Variable = "$.jobStatus.Jobs[0].Status"
                  StringEquals = "FAILED"
                  Next = "ChunkFailed"
                }
              ]
              Default = "WaitForBatchJob"
            }
            
            ChunkComplete = {
              Type = "Succeed"
            }
            
            ChunkFailed = {
              Type = "Fail"
              Cause = "Chunk processing failed"
              Error = "ChunkError"
            }
          }
        }
        ResultPath = "$.parallelResults"
        Next = "AggregateResults"
      }
      
      AggregateResults = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[3]}"
        InputPath = "$.parallelResults"
        ResultPath = "$.aggregatedResults"
        Next = "DeploymentChoiceState"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "ReportFailure"
            ResultPath = "$.errorCause"
          }
        ]
      }
      
      DeploymentChoiceState = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.aggregatedResults.deployment"
            StringMatches = "CORE"
            Next = "SendToSqsCore"
          }
        ]
        Default = "SendToKafka"
      }
      
      SendToKafka = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[4]}"
        InputPath = "$.aggregatedResults"
        ResultPath = "$.kafkaResults"
        Next = "SendToKafkaChoice"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "ReportFailure"
            ResultPath = "$.kafkaResults"
          }
        ]
      }
      
      SendToKafkaChoice = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.kafkaResults.batchStatus"
            StringMatches = "SUBMISSION_FAILED"
            Next = "ReportFailure"
          }
        ]
        Default = "SendToSQS"
      }
      
      SendToSqsCore = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[5]}"
        InputPath = "$.aggregatedResults"
        ResultPath = "$.sqsCoreResults"
        Next = "SendToSQSCoreChoice"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "ReportFailure"
            ResultPath = "$.sqsCoreResults"
          }
        ]
      }
      
      SendToSQSCoreChoice = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.sqsCoreResults.batchStatus"
            StringMatches = "SUBMISSION_FAILED"
            Next = "ReportFailure"
          }
        ]
        Default = "SendToSQS"
      }
      
      SendToSQS = {
        Type = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Parameters = {
          QueueUrl = "https://sqs.${var.aws_region}.amazonaws.com/*/batch-proc"
          MessageBody = {
            "batchId.$" = "$.aggregatedResults.batchId"
            "batchStatus" = "SUBMITTED_FOR_PROCESSING"
            "customerId.$" = "$.aggregatedResults.customerId"
            "notificationId.$" = "States.UUID()"
            "progress.$" = "$.aggregatedResults.progress"
            "totalRecordsProcessed.$" = "$.aggregatedResults.totalRecordsProcessed"
            "processingTime.$" = "$.aggregatedResults.processingTime"
          }
        }
        Next = "SuccessState"
      }
      
      ReportFailure = {
        Type = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Parameters = {
          QueueUrl = "https://sqs.${var.aws_region}.amazonaws.com/*/batch-proc"
          MessageBody = {
            "batchId.$" = "$.batchConfig.batchId"
            "batchStatus.$" = "$.batchConfig.batchStatus"
            "customerId.$" = "$.batchConfig.customerId"
            "notificationId.$" = "States.UUID()"
            "errorMessage.$" = "$.errorCause.errorMessage"
            "progress.$" = "$.batchConfig.progress"
          }
        }
        Next = "FailureState"
      }
      
      SuccessState = {
        Type = "Succeed"
      }
      
      FailureState = {
        Type = "Fail"
        Cause = "Batch Processing Failed"
        Error = "StepFunctionError"
      }
    }
  })
} 
