variable "lambda_packages_bucket" {
  description = "S3 bucket name for Lambda packages"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "lambdas" {
  description = "Map of Lambda configurations for deployment"
  type = map(object({
    function_name    = string
    handler          = string
    runtime          = string
    memory_size      = string
    timeout          = number
    description      = string
    create_role      = bool
    publish          = bool
    s3_bucket        = string
    s3_key           = string
    source_code_hash = string
    tags             = map(string)
  }))
} 