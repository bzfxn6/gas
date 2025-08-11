variable "lambda_packages_bucket" {
  description = "S3 bucket name for Lambda packages"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "lambdas" {
  description = "Map of Lambda configurations for building packages"
  type = map(object({
    function_name = string
    handler       = string
    runtime       = string
    memory_size   = string
    timeout       = number
    description   = string
    create_role   = bool
    publish       = bool
    source_file   = string
    package_key   = string
    hash_file     = string
    tags          = map(string)
  }))
} 