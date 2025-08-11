terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-role?ref=v5.30.0"
}

inputs = {
  role_name = "test-lambda-role"
  
  create_role = true
  role_description = "Test role for Lambda function"
  
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
  
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
} 