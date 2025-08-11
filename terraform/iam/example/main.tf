provider "aws" {
  region = "eu-west-1"
}

# Create the base roles
module "iam_roles" {
  source = "../"

  roles = {
    # EC2 instance role
    ec2_role = {
      name = "my-app-ec2-role"
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
      tags = {
        Project = "MyApp"
        Type    = "EC2"
      }
    }

    # Lambda execution role
    lambda_role = {
      name = "my-app-lambda-role"
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
      tags = {
        Project = "MyApp"
        Type    = "Lambda"
      }
    }

    # ECS task role
    ecs_role = {
      name = "my-app-ecs-role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
              Service = "ecs-tasks.amazonaws.com"
            }
          }
        ]
      })
      tags = {
        Project = "MyApp"
        Type    = "ECS"
      }
    }
  }
}

# Attach base policies to the roles
module "base_policies" {
  source = "../"

  role_arns = module.iam_roles.role_arns

  policies = {
    # CloudWatch Logs policy for Lambda
    lambda_logs = {
      name = "my-app-lambda-logs"
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
            Resource = "arn:aws:logs:*:*:*"
          }
        ]
      })
      role_key = "lambda_role"
    }

    # S3 access policy for EC2
    ec2_s3 = {
      name = "my-app-ec2-s3"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:ListBucket"
            ]
            Resource = [
              "arn:aws:s3:::my-app-bucket",
              "arn:aws:s3:::my-app-bucket/*"
            ]
          }
        ]
      })
      role_key = "ec2_role"
    }

    # ECS task execution policy
    ecs_execution = {
      name = "my-app-ecs-execution"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage"
            ]
            Resource = "*"
          }
        ]
      })
      role_key = "ecs_role"
    }
  }
}

# Example of how another app can attach their own policies
module "app_specific_policies" {
  source = "../"

  role_arns = module.iam_roles.role_arns

  policies = {
    # App-specific S3 policy
    app_s3 = {
      name = "my-app-specific-s3"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject"
            ]
            Resource = "arn:aws:s3:::app-specific-bucket/*"
          }
        ]
      })
      role_key = "ec2_role"
    }

    # App-specific DynamoDB policy
    app_dynamodb = {
      name = "my-app-specific-dynamodb"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "dynamodb:GetItem",
              "dynamodb:PutItem",
              "dynamodb:UpdateItem",
              "dynamodb:DeleteItem",
              "dynamodb:Query",
              "dynamodb:Scan"
            ]
            Resource = "arn:aws:dynamodb:*:*:table/my-app-table"
          }
        ]
      })
      role_key = "lambda_role"
    }
  }
}

# Output the role and policy ARNs
output "role_arns" {
  description = "ARNs of the created IAM roles"
  value = module.iam_roles.role_arns
}

output "base_policy_arns" {
  description = "ARNs of the base IAM policies"
  value = module.base_policies.policy_arns
}

output "app_specific_policy_arns" {
  description = "ARNs of the app-specific IAM policies"
  value = module.app_specific_policies.policy_arns
} 