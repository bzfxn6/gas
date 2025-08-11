# IAM role for Lambda functions
resource "aws_iam_role" "lambda" {
  for_each = var.lambdas

  name = "${each.value.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(each.value.tags, {
    Name = "${each.value.function_name}-role"
  })
}

# IAM policy for CloudWatch Logs
resource "aws_iam_role_policy" "lambda_logs" {
  for_each = var.lambdas

  name = "${each.value.function_name}-logs-policy"
  role = aws_iam_role.lambda[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${each.value.function_name}:*"
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  for_each = var.lambdas

  name              = "/aws/lambda/${each.value.function_name}"
  retention_in_days = 7

  tags = merge(each.value.tags, {
    Name = "${each.value.function_name}-logs"
  })
}

# Lambda function
resource "aws_lambda_function" "lambda" {
  for_each = var.lambdas

  function_name = each.value.function_name
  description   = each.value.description
  role          = aws_iam_role.lambda[each.key].arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  memory_size   = each.value.memory_size
  timeout       = each.value.timeout
  publish       = each.value.publish

  # Use S3 package
  s3_bucket         = each.value.s3_bucket
  s3_key            = each.value.s3_key
  source_code_hash  = each.value.source_code_hash

  tags = merge(each.value.tags, {
    Name = each.value.function_name
  })

  depends_on = [
    aws_iam_role_policy.lambda_logs,
    aws_cloudwatch_log_group.lambda
  ]
}

# Outputs
output "lambda_functions" {
  description = "Deployed Lambda functions"
  value = {
    for k, v in aws_lambda_function.lambda : k => {
      function_name = v.function_name
      arn           = v.arn
      invoke_arn    = v.invoke_arn
      role_arn      = v.role
      log_group     = aws_cloudwatch_log_group.lambda[k].name
    }
  }
}

output "lambda_roles" {
  description = "Lambda IAM roles"
  value = {
    for k, v in aws_iam_role.lambda : k => {
      role_name = v.name
      role_arn  = v.arn
    }
  }
} 