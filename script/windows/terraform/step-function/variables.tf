variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "step_function_name" {
  description = "Name of the Step Function"
  type        = string
  default     = "three-lambda-workflow"
}

variable "lambda_functions" {
  description = "List of Lambda function names"
  type        = list(string)
  default     = ["one", "two", "three"]
} 