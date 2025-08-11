# AWS Provider configuration
provider "aws" {
  region = "eu-west-1"
}

# Create OIDC Provider
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  url             = var.oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  tags            = var.tags
}

# Create IAM Role for Service Account (IRSA)
resource "aws_iam_role" "s3_upload_role" {
  name = "eks-s3-upload-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Create policy for S3 and EventBridge access
resource "aws_iam_policy" "s3_upload_policy" {
  name        = "s3-upload-pics-policy"
  description = "Policy for uploading to upload-pics bucket and creating EventBridge rules"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::upload-pics",
          "arn:aws:s3:::upload-pics/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutRule",
          "events:PutTargets",
          "events:DeleteRule",
          "events:RemoveTargets",
          "events:DisableRule",
          "events:EnableRule",
          "events:ListRules",
          "events:ListTargetsByRule"
        ]
        Resource = [
          "arn:aws:events:eu-west-1:*:rule/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/eventbridgetoSQS"
        ]
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "s3_upload_policy_attachment" {
  role       = aws_iam_role.s3_upload_role.name
  policy_arn = aws_iam_policy.s3_upload_policy.arn
} 