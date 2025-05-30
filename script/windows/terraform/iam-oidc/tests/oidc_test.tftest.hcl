# Test variables for different environments
variables {
  oidc_url = "https://oidc.eks.eu-west-1.amazonaws.com/id/TEST123"
  namespace = "test-namespace"
  service_account_name = "test-sa"
  tags = {
    Environment = "test"
  }
}

# Test OIDC provider configuration
run "verify_oidc_provider" {
  command = plan

  assert {
    condition     = aws_iam_openid_connect_provider.oidc_provider.url == var.oidc_url
    error_message = "OIDC provider URL did not match expected value from environment variable"
  }

  assert {
    condition     = contains(aws_iam_openid_connect_provider.oidc_provider.client_id_list, "sts.amazonaws.com")
    error_message = "OIDC provider client ID list did not contain sts.amazonaws.com"
  }

  assert {
    condition     = aws_iam_openid_connect_provider.oidc_provider.tags["Environment"] == jsondecode(var.tags)["Environment"]
    error_message = "OIDC provider tags did not match environment variable tags"
  }
}

# Test S3 permissions
run "verify_s3_permissions" {
  command = plan

  assert {
    condition     = can(regex("s3:PutObject", aws_iam_policy.s3_upload_policy.policy))
    error_message = "S3 policy does not contain PutObject permission"
  }

  assert {
    condition     = can(regex("arn:aws:s3:::${var.test_bucket}", aws_iam_policy.s3_upload_policy.policy))
    error_message = "S3 policy does not reference test bucket from environment variable"
  }

  assert {
    condition     = can(regex("s3:GetObject", aws_iam_policy.s3_upload_policy.policy))
    error_message = "S3 policy does not contain GetObject permission"
  }

  assert {
    condition     = can(regex("s3:ListBucket", aws_iam_policy.s3_upload_policy.policy))
    error_message = "S3 policy does not contain ListBucket permission"
  }
}

# Test EventBridge permissions
run "verify_eventbridge_permissions" {
  command = plan

  assert {
    condition     = can(regex("events:PutRule", aws_iam_policy.s3_upload_policy.policy))
    error_message = "Policy does not contain EventBridge PutRule permission"
  }

  assert {
    condition     = can(regex("iam:PassRole", aws_iam_policy.s3_upload_policy.policy))
    error_message = "Policy does not contain IAM PassRole permission"
  }

  assert {
    condition     = can(regex("arn:aws:iam::\\*:role/${var.test_role}", aws_iam_policy.s3_upload_policy.policy))
    error_message = "Policy does not reference test role from environment variable"
  }
}

# Test role assumption policy
run "verify_role_assumption" {
  command = plan

  assert {
    condition     = can(regex("sts:AssumeRoleWithWebIdentity", aws_iam_role.s3_upload_role.assume_role_policy))
    error_message = "Role does not have AssumeRoleWithWebIdentity permission"
  }

  assert {
    condition     = can(regex("system:serviceaccount:${var.namespace}:${var.service_account_name}", aws_iam_role.s3_upload_role.assume_role_policy))
    error_message = "Role does not allow assumption by the correct service account from environment variables"
  }
}

# Test with different environment variables
run "verify_prod_environment" {
  command = plan

  # Override environment variables for this test
  variables {
    oidc_url = "https://oidc.eks.eu-west-1.amazonaws.com/id/PROD123"
    namespace = "prod-namespace"
    service_account_name = "prod-sa"
    tags = {
      Environment = "prod"
    }
  }

  assert {
    condition     = aws_iam_openid_connect_provider.oidc_provider.url == var.oidc_url
    error_message = "OIDC provider URL did not match prod environment value"
  }

  assert {
    condition     = aws_iam_openid_connect_provider.oidc_provider.tags["Environment"] == "prod"
    error_message = "OIDC provider tags did not match prod environment"
  }
}

# Test with invalid configuration
run "verify_invalid_configuration" {
  command = plan
  expect_failures = [
    aws_iam_openid_connect_provider.oidc_provider,
  ]

  variables {
    oidc_url = "invalid-url"
  }
} 