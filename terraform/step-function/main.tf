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

# IAM Policy for Step Function to invoke Lambda and SQS
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
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
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
        Next = "ValidateDataWithLambda"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "ReportFailure"
            ResultPath = "$.errorCause"
          }
        ]
      }
      
      ValidateDataWithLambda = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[1]}"
        Parameters = {
          "bucket.$" = "$.batchConfig.bucket"
          "file.$" = "$.batchConfig.file"
          "customerId.$" = "$.batchConfig.customerId"
          "tenantId.$" = "$.batchConfig.tenantId"
          "batchId.$" = "$.batchConfig.batchId"
          "deployment.$" = "$.batchConfig.deployment"
          "snapshotId.$" = "$.batchConfig.snapshotId"
        }
        ResultPath = "$.validationResult"
        Next = "CheckValidationResults"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "ValidationFailed"
            ResultPath = "$.validationError"
          }
        ]
      }
      
      CheckValidationResults = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.validationResult.body.validationResults.status"
            StringEquals = "PASSED"
            Next = "CalculateChunks"
          },
          {
            Variable = "$.validationResult.body.validationResults.batchStatus"
            StringEquals = "VALIDATION_FAILED_CRITICAL"
            Next = "ReportCriticalValidationFailure"
          }
        ]
        Default = "ReportValidationFailure"
      }
      
      ReportCriticalValidationFailure = {
        Type = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Parameters = {
          QueueUrl = "https://sqs.${var.aws_region}.amazonaws.com/*/batch-proc"
          MessageBody = {
            "batchId.$" = "$.batchConfig.batchId"
            "batchStatus" = "VALIDATION_FAILED_CRITICAL"
            "customerId.$" = "$.batchConfig.customerId"
            "tenantId.$" = "$.batchConfig.tenantId"
            "notificationId.$" = "States.UUID()"
            "errorMessage.$" = "$.validationResult.body.validationResults.errorMessage"
            "criticalIssues.$" = "$.validationResult.body.validationResults.validationSummary.criticalIssues"
            "validationSummary.$" = "$.validationResult.body.validationResults.validationSummary"
            "missingRecordPatterns.$" = "$.validationResult.body.validationResults.missingRecordPatterns"
            "severity" = "CRITICAL"
            "requiresImmediateAttention" = true
          }
        }
        Next = "FailureState"
      }
      
      ValidationFailed = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[0]}"
        Parameters = {
          "action": "getValidationErrors"
          "batchId.$" = "$.batchConfig.batchId"
          "bucket.$" = "$.batchConfig.bucket"
        }
        ResultPath = "$.validationErrors"
        Next = "ReportValidationFailure"
      }
      
      ReportValidationFailure = {
        Type = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Parameters = {
          QueueUrl = "https://sqs.${var.aws_region}.amazonaws.com/*/batch-proc"
          MessageBody = {
            "batchId.$" = "$.batchConfig.batchId"
            "batchStatus" = "VALIDATION_FAILED"
            "customerId.$" = "$.batchConfig.customerId"
            "notificationId.$" = "States.UUID()"
            "errorMessage.$" = "$.validationErrors.errorMessage"
            "validationErrors.$" = "$.validationErrors.validationErrors"
            "validationSummary.$" = "$.validationErrors.validationSummary"
          }
        }
        Next = "FailureState"
      }
      
      CalculateChunks = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[2]}"
        Parameters = {
          "bucket.$" = "$.batchConfig.bucket"
          "file.$" = "$.batchConfig.file"
          "customerId.$" = "$.batchConfig.customerId"
          "tenantId.$" = "$.batchConfig.tenantId"
          "batchId.$" = "$.batchConfig.batchId"
          "deployment.$" = "$.batchConfig.deployment"
          "snapshotId.$" = "$.batchConfig.snapshotId"
          "destination" = var.record_destination
        }
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
              Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[3]}"
              Parameters = {
                "chunkId.$" = "$.chunkId"
                "startIndex.$" = "$.startIndex"
                "endIndex.$" = "$.endIndex"
                "bucket.$" = "$.bucket"
                "file.$" = "$.file"
                "customerId.$" = "$.customerId"
                "tenantId.$" = "$.tenantId"
                "batchId.$" = "$.batchId"
                "destination.$" = "$.destination"
              }
              ResultPath = "$.lambdaResult"
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
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[4]}"
        Parameters = {
          "batchId.$" = "$.batchConfig.batchId"
          "customerId.$" = "$.batchConfig.customerId"
          "tenantId.$" = "$.batchConfig.tenantId"
          "file.$" = "$.batchConfig.file"
        }
        ResultPath = "$.aggregatedResults"
        Next = "FileComplete"
      }
      
      FileComplete = {
        Type = "Pass"
        Next = "AllFilesComplete"
      }
      
      AllFilesComplete = {
        Type = "Pass"
        Next = "FinalAggregation"
      }
      
      FinalAggregation = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[4]}"
        Parameters = {
          "batchId.$" = "$.batchId"
          "customerId.$" = "$.customerId"
          "tenantId.$" = "$.tenantId"
        }
        ResultPath = "$.finalResults"
        Next = "SendToKafka"
      }
      
      SendToKafka = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[5]}"
        Parameters = {
          "message.$" = "$.finalResults"
          "kafkaBrokers" = var.kafka_brokers
          "kafkaTopic" = var.kafka_topic
        }
        Next = "SendToSqsCore"
      }
      
      SendToSqsCore = {
        Type = "Task"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[6]}"
        Parameters = {
          "message.$" = "$.finalResults"
          "sqsQueueUrl" = var.sqs_core_queue_url
        }
        Next = "Success"
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

# Lambda Reserved Concurrency for parallel processing
resource "aws_lambda_function" "batch_processor_lambda" {
  count = length(var.lambda_functions)
  
  filename         = "lambda_functions/${var.lambda_functions[count.index]}.zip"
  function_name    = var.lambda_functions[count.index]
  role            = aws_iam_role.lambda_role.arn
  handler         = "${var.lambda_functions[count.index]}.lambda_handler"
  runtime         = "python3.9"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  
  reserved_concurrent_executions = count.index == 2 ? 200 : 50  # 200 for update-records Lambda, 50 for others
  
  environment {
    variables = {
      S3_BUCKET_NAME = var.s3_bucket_name
      KAFKA_BROKERS  = var.kafka_brokers
      KAFKA_TOPIC    = var.kafka_topic
      SQS_CORE_QUEUE = var.sqs_core_queue_url
      RECORD_DESTINATION = var.record_destination
    }
  }
  
  tags = {
    Name = var.lambda_functions[count.index]
    Environment = var.environment
  }
} 
