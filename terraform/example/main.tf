provider "aws" {
  region = "eu-west-1"
}

module "sqs" {
  source = "../"

  resource_prefix    = "example"
  region            = "eu-west-1"
  aws_number_account = "123456789012"
  custom_prefix     = "myapp"

  sns_topics = {
    # Standard queue with no policy
    standard-queue = {
      message_retention_seconds = 86400
      tags = {
        Project = "Example"
      }
    }

    # FIFO queue with DLQ
    fifo-queue = {
      fifo_queue                = true
      deadletter                = true
      max_receive_count         = 3
      message_retention_seconds = 345600
      tags = {
        Project = "Example"
      }
    }

    # Queue with S3 notification policy
    s3-notification-queue = {
      resource_based_policy_enabled = true
      s3_send_allowed_arns = [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-other-bucket"
      ]
      tags = {
        Project = "Example"
      }
    }

    # Queue with SNS notification policy
    sns-notification-queue = {
      resource_based_policy_enabled = true
      sns_send_allowed_arns = [
        "arn:aws:sns:eu-west-1:123456789012:my-topic"
      ]
      tags = {
        Project = "Example"
      }
    }

    # Queue with IAM access policy
    iam-access-queue = {
      resource_based_policy_enabled = true
      iam_send_allowed_arns = [
        "arn:aws:iam::123456789012:role/my-role"
      ]
      tags = {
        Project = "Example"
      }
    }

    # Queue with full management access
    managed-queue = {
      resource_based_policy_enabled = true
      manage_allowed_arns = [
        "arn:aws:iam::123456789012:role/admin-role"
      ]
      tags = {
        Project = "Example"
      }
    }

    # Queue with read-only access
    read-only-queue = {
      resource_based_policy_enabled = true
      read_allowed_arns = [
        "arn:aws:iam::123456789012:role/read-only-role"
      ]
      tags = {
        Project = "Example"
      }
    }

    # Queue with custom IAM policy
    custom-policy-queue = {
      resource_based_policy_enabled = true
      custom_iam_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::123456789012:role/custom-role"
            }
            Action = [
              "sqs:SendMessage",
              "sqs:ReceiveMessage"
            ]
            Resource = "*"
          }
        ]
      })
      tags = {
        Project = "Example"
      }
    }

    # Queue with SSM parameter
    ssm-queue = {
      ssm_name = "my-queue"
      tags = {
        Project = "Example"
      }
    }
  }
}

# Create the base roles
module "iam_roles" {
  source = "../"

  roles = {
    app_role = {
      name = "my-app-role"
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
      }
    }
  }
}

# Attach policies to the roles
module "iam_policies" {
  source = "../"

  role_arns = module.iam_roles.role_arns

  policies = {
    s3_access = {
      name = "my-app-s3-access"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject"
            ]
            Resource = "arn:aws:s3:::my-bucket/*"
          }
        ]
      })
      role_key = "app_role"
    }
  }
}

# Output the queue URLs and ARNs
output "queue_urls" {
  description = "URLs of the created SQS queues"
  value = {
    for k, v in module.sqs.queue_urls : k => v
  }
}

output "queue_arns" {
  description = "ARNs of the created SQS queues"
  value = {
    for k, v in module.sqs.queue_arns : k => v
  }
}

output "dlq_urls" {
  description = "URLs of the created DLQ queues"
  value = {
    for k, v in module.sqs.dlq_urls : k => v
  }
}

output "dlq_arns" {
  description = "ARNs of the created DLQ queues"
  value = {
    for k, v in module.sqs.dlq_arns : k => v
  }
}

output "ssm_parameters" {
  description = "Created SSM parameters"
  value = {
    for k, v in module.sqs.ssm_parameters : k => v
  }
}

# Output the role and policy ARNs
output "role_arns" {
  value = module.iam_roles.role_arns
}

output "policy_arns" {
  value = module.iam_policies.policy_arns
} 