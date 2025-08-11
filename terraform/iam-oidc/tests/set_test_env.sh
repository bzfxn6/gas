#!/bin/bash

# Test environment variables
export TF_VAR_oidc_url="https://oidc.eks.eu-west-1.amazonaws.com/id/TEST123"
export TF_VAR_namespace="test-namespace"
export TF_VAR_service_account_name="test-sa"

# Test tags as JSON
export TF_VAR_tags='{"Environment":"test","Project":"test-project","Owner":"test-team"}'

# Test bucket and role names
export TF_VAR_test_bucket="test-upload-pics"
export TF_VAR_test_role="test-eventbridgetoSQS"

# AWS region for testing
export TF_VAR_aws_region="eu-west-1"

echo "Test environment variables set:"
echo "OIDC URL: $TF_VAR_oidc_url"
echo "Namespace: $TF_VAR_namespace"
echo "Service Account: $TF_VAR_service_account_name"
echo "Tags: $TF_VAR_tags"
echo "Test Bucket: $TF_VAR_test_bucket"
echo "Test Role: $TF_VAR_test_role"
echo "AWS Region: $TF_VAR_aws_region" 