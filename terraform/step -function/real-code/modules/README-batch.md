# AWS Batch Terragrunt Module

This module provides AWS Batch infrastructure for the hybrid batch processing approach, where:
- **Lambda** processes small chunks (≤290K records)
- **AWS Batch** processes large chunks (>290K records)

## Overview

The AWS Batch module creates:
- **Compute Environment**: EC2-based compute resources for batch processing
- **Job Queue**: Queue for managing batch job submissions
- **Job Definitions**: Container definitions for validation and processing jobs
- **Launch Template**: EC2 instance configuration
- **CloudWatch Log Groups**: Logging for batch jobs

## Prerequisites

### 1. IAM Roles
You need to create the following IAM roles in your `iam-roles` module:

```hcl
# In your iam-roles module
scm-batch-processor-batch-role = {
  # Service role for AWS Batch
  # Permissions: AWSBatchServiceRole
}

scm-batch-processor-batch-instance-role = {
  # Instance profile for EC2 instances
  # Permissions: S3, CloudWatch, ECS, etc.
}
```

### 2. Security Groups
Create a security group for batch processing:

```hcl
# In your security-group module
scm-batch-processor-batch = {
  # Security group for batch instances
  # Rules: Outbound to S3, CloudWatch, MSK, SQS
}
```

### 3. Modules Configuration
Add the batch module to your `modules.hcl`:

```hcl
# In modules.hcl
module_urls = {
  batch_ext = "git::https://github.com/your-org/terraform-aws-batch.git"
}

# In version.hcl
module_versions = {
  batch_ext = "v1.0.0"
}
```

## Module Structure

```
modules/
├── batch.hcl                    # Main Terragrunt configuration
├── batch-json/                  # JSON configuration files
│   ├── compute-environment.json # Compute environment configuration
│   ├── job-queue.json          # Job queue configuration
│   ├── batch-validation-job.json # Validation job definition
│   ├── batch-processing-job.json # Processing job definition
│   ├── launch-template.json    # EC2 launch template
│   └── log-groups.json         # CloudWatch log groups
├── batch_user_data.sh          # EC2 user data script (from parent)
└── README-batch.md             # This file
```

## Configuration

The module uses JSON files for configuration, following the same pattern as the Lambda module. Each JSON file defines a specific AWS Batch resource:

### JSON Configuration Files

#### 1. `compute-environment.json`
- **Type**: MANAGED (AWS manages the underlying infrastructure)
- **Instance Types**: c5.4xlarge, c5.2xlarge, c5.xlarge (high CPU)
- **Capacity**: 0-256 vCPUs (scales based on demand)
- **Spot Instances**: 100% bid percentage for cost optimization

#### 2. `job-queue.json`
- **Queue Management**: Job scheduling and prioritization
- **Compute Environment**: Links to the compute environment
- **State**: ENABLED for active processing

#### 3. `batch-validation-job.json`
- **Purpose**: Validates entire files before processing
- **Resources**: 4 vCPUs, 8GB memory
- **Timeout**: 2 hours
- **Retries**: 3 attempts
- **Command**: Runs `batch_validator.py` script

#### 4. `batch-processing-job.json`
- **Purpose**: Processes individual chunks
- **Resources**: 4 vCPUs, 8GB memory
- **Timeout**: 2 hours
- **Retries**: 3 attempts
- **Environment Variables**:
  - `KAFKA_BROKERS`: MSK broker endpoints
  - `KAFKA_TOPIC`: Kafka topic for processed records
  - `SQS_CORE_QUEUE`: SQS queue URL
  - `RECORD_DESTINATION`: "kafka" or "sqs_core"
- **Command**: Runs `batch_processor.py` script

#### 5. `launch-template.json`
- **AMI**: Amazon Linux 2 ECS-Optimized
- **Instance Type**: c5.4xlarge
- **Storage**: 100GB GP3 encrypted volume
- **Monitoring**: Enhanced monitoring enabled
- **Security Groups**: Batch-specific security group

#### 6. `log-groups.json`
- **Validation Logs**: `/aws/batch/{prefix}-batch-validation`
- **Processing Logs**: `/aws/batch/{prefix}-batch-processing`
- **Retention**: 30 days

### Customizing JSON Files

You can customize any of these JSON files to match your specific requirements:

#### Example: Modifying Instance Types
```json
// compute-environment.json
{
  "compute_resources": {
    "instance_types": [
      "c5.8xlarge",  // Larger instances for more memory
      "c5.4xlarge",
      "c5.2xlarge"
    ]
  }
}
```

#### Example: Changing Resource Allocation
```json
// batch-processing-job.json
{
  "container_properties": {
    "vcpus": 8,      // More vCPUs
    "memory": 16384  // 16GB memory
  }
}
```

#### Example: Adding Environment Variables
```json
// batch-processing-job.json
{
  "container_properties": {
    "environment": [
      {
        "name": "CUSTOM_VAR",
        "value": "custom_value"
      }
    ]
  }
}
```

## Usage

### 1. Deploy the Module
```bash
cd terraform/step-function/real-code/modules
terragrunt plan
terragrunt apply
```

### 2. Update Step Function
The Step Function will automatically use AWS Batch for chunks >290K records:

```hcl
# In your step-function.hcl
dependency "batch" {
  config_path = "../batch"
}

# The Step Function will reference:
# - aws_batch_job_queue.batch_processing_queue.arn
# - aws_batch_job_definition.batch_processing_job.arn
# - aws_batch_job_definition.batch_validation_job.arn
```

### 3. Monitor Jobs
```bash
# View job queue
aws batch describe-job-queues --job-queues gss-dev-batch-queue

# View compute environment
aws batch describe-compute-environments --compute-environments gss-dev-batch-compute

# View job status
aws batch describe-jobs --jobs job-12345678-1234-1234-1234-123456789012
```

## Environment Variables

### Required Environment Variables
- `AWS_REGION`: AWS region
- `S3_BUCKET`: S3 bucket for data storage
- `KAFKA_BROKERS`: MSK broker endpoints
- `KAFKA_TOPIC`: Kafka topic name
- `SQS_CORE_QUEUE`: SQS queue URL
- `RECORD_DESTINATION`: "kafka" or "sqs_core"

### Optional Environment Variables
- `BATCH_PROCESSING_THRESHOLD`: Record threshold for Batch vs Lambda (default: 290000)

## Cost Optimization

### 1. Spot Instances
- Uses 100% spot instances for cost savings
- Automatic fallback to on-demand if needed

### 2. Instance Sizing
- c5.4xlarge: High CPU, cost-effective for processing
- Auto-scaling: Scales down to 0 when not in use

### 3. Storage
- GP3 volumes: Better performance, lower cost
- 100GB default: Adjust based on your data size

## Monitoring and Logging

### CloudWatch Logs
- **Validation Logs**: `/aws/batch/{prefix}-batch-validation`
- **Processing Logs**: `/aws/batch/{prefix}-batch-processing`
- **Retention**: 30 days

### Metrics
- Job success/failure rates
- Processing time per chunk
- Resource utilization
- Cost metrics

## Troubleshooting

### Common Issues

#### 1. Job Stuck in RUNNABLE
```bash
# Check compute environment status
aws batch describe-compute-environments --compute-environments gss-dev-batch-compute

# Check for capacity issues
aws batch describe-job-queues --job-queues gss-dev-batch-queue
```

#### 2. Job Failing
```bash
# Check job logs
aws logs describe-log-streams --log-group-name "/aws/batch/gss-dev-batch-processing"

# Get job details
aws batch describe-jobs --jobs job-12345678-1234-1234-1234-123456789012
```

#### 3. Permission Issues
```bash
# Verify IAM roles
aws iam get-role --role-name gss-dev-scm-batch-processor-batch-role
aws iam get-instance-profile --instance-profile-name gss-dev-scm-batch-processor-batch-instance-role
```

### Debug Commands
```bash
# List all batch resources
aws batch describe-job-definitions
aws batch describe-job-queues
aws batch describe-compute-environments

# Monitor job progress
aws batch list-jobs --job-queue gss-dev-batch-queue --job-status RUNNING
```

## Security

### Network Security
- Instances run in private subnets
- Security group restricts outbound traffic
- No inbound access required

### Data Security
- EBS volumes encrypted at rest
- S3 access via IAM roles
- MSK authentication via IAM

### IAM Security
- Least privilege principle
- Separate roles for service and instances
- No long-term credentials

## Scaling

### Automatic Scaling
- Scales from 0 to 256 vCPUs based on demand
- Spot instances for cost optimization
- Automatic instance termination when idle

### Manual Scaling
```bash
# Update compute environment
aws batch update-compute-environment \
  --compute-environment gss-dev-batch-compute \
  --compute-resources desiredVcpus=128
```

## Integration with Step Function

The Step Function automatically routes chunks based on size:

```json
{
  "ProcessChunk": {
    "Type": "Choice",
    "Choices": [
      {
        "Variable": "$.chunkSize",
        "NumericGreaterThan": 290000,
        "Next": "SubmitBatchJob"
      }
    ],
    "Default": "ProcessWithLambda"
  }
}
```

This ensures optimal resource usage and cost efficiency.

## Support

For issues or questions:
1. Check CloudWatch logs for detailed error messages
2. Review IAM permissions and security group rules
3. Verify network connectivity to S3, MSK, and SQS
4. Check compute environment capacity and scaling 