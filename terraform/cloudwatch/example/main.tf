module "cloudwatch_dashboards" {
  source = "../"
  
  region      = "us-east-1"
  environment = "prod"
  project     = "gas"
  
  dashboards = {
    # Example 1: Lambda monitoring dashboard
    lambda_monitoring = {
      name = "lambda-monitoring-${var.environment}"
      dashboard_body = jsonencode({
        widgets = [
          {
            type   = "metric"
            x      = 0
            y      = 0
            width  = 12
            height = 6
            properties = {
              metrics = [
                ["AWS/Lambda", "Invocations", "FunctionName", "my-function"],
                [".", "Errors", ".", "."],
                [".", "Duration", ".", "."]
              ]
              period = 300
              stat   = "Sum"
              region = var.region
              title  = "Lambda Function Metrics"
            }
          }
        ]
      })
      tags = {
        Environment = var.environment
        Project     = var.project
        Service     = "lambda"
      }
    }
    
    # Example 2: SQS monitoring dashboard
    sqs_monitoring = {
      name = "sqs-monitoring-${var.environment}"
      dashboard_body = jsonencode({
        widgets = [
          {
            type   = "metric"
            x      = 0
            y      = 0
            width  = 12
            height = 6
            properties = {
              metrics = [
                ["AWS/SQS", "NumberOfMessagesReceived", "QueueName", "my-queue"],
                [".", "NumberOfMessagesSent", ".", "."],
                [".", "ApproximateNumberOfMessagesVisible", ".", "."]
              ]
              period = 300
              stat   = "Sum"
              region = var.region
              title  = "SQS Queue Metrics"
            }
          }
        ]
      })
      tags = {
        Environment = var.environment
        Project     = var.project
        Service     = "sqs"
      }
    }
    
    # Example 3: Step Function monitoring dashboard
    step_function_monitoring = {
      name = "step-function-monitoring-${var.environment}"
      dashboard_body = jsonencode({
        widgets = [
          {
            type   = "metric"
            x      = 0
            y      = 0
            width  = 12
            height = 6
            properties = {
              metrics = [
                ["AWS/States", "ExecutionsStarted", "StateMachineName", "my-state-machine"],
                [".", "ExecutionsSucceeded", ".", "."],
                [".", "ExecutionsFailed", ".", "."],
                [".", "ExecutionTime", ".", "."]
              ]
              period = 300
              stat   = "Sum"
              region = var.region
              title  = "Step Function Metrics"
            }
          }
        ]
      })
      tags = {
        Environment = var.environment
        Project     = var.project
        Service     = "step-function"
      }
    }
  }
}

# Example variables for the example
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "gas"
} 