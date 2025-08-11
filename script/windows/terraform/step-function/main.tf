provider "aws" {
  region = var.aws_region
}

# Lambda functions
resource "aws_lambda_function" "one" {
  filename         = "lambda_one.zip"
  function_name    = "one"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  source_code_hash = filebase64sha256("lambda_one.zip")
}

resource "aws_lambda_function" "two" {
  filename         = "lambda_two.zip"
  function_name    = "two"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  source_code_hash = filebase64sha256("lambda_two.zip")
}

resource "aws_lambda_function" "three" {
  filename         = "lambda_three.zip"
  function_name    = "three"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  source_code_hash = filebase64sha256("lambda_three.zip")
}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

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

# IAM Policy for Step Function to invoke Lambda
resource "aws_iam_role_policy" "step_function_policy" {
  name = "step_function_policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          for func in var.lambda_functions :
          "arn:aws:lambda:${var.aws_region}:*:function:${func}"
        ]
      }
    ]
  })
}

# Step Function Definition
resource "aws_sfn_state_machine" "example" {
  name     = var.step_function_name
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "A workflow that calls three Lambda functions in sequence"
    StartAt = "CallLambdaOne"
    States = {
      CallLambdaOne = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[0]}"
          Payload = {
            "input.$" = "$"
          }
        }
        Next = "CallLambdaTwo"
      }
      CallLambdaTwo = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[1]}"
          Payload = {
            "input.$" = "$"
          }
        }
        Next = "CallLambdaThree"
      }
      CallLambdaThree = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = "arn:aws:lambda:${var.aws_region}:*:function:${var.lambda_functions[2]}"
          Payload = {
            "input.$" = "$"
          }
        }
        End = true
      }
    }
  })
} 