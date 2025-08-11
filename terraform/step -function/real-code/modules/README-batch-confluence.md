# AWS Batch Module - Confluence Documentation

h1. Overview

The AWS Batch module provides infrastructure for hybrid batch processing, where:
* *Lambda* processes small chunks (≤290K records)
* *AWS Batch* processes large chunks (>290K records)

This approach optimizes cost and performance by using the most appropriate compute resource for each workload size.

h2. Architecture

{code:json}
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Step Function │    │   AWS Lambda    │    │   AWS Batch     │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Initialize  │ │    │ │ Small Chunks│ │    │ │ Large Chunks│ │
│ │             │ │    │ │ ≤290K       │ │    │ │ >290K       │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Validate    │ │    │ │ Fast Startup│ │    │ │ High Memory │ │
│ │ (Batch)     │ │    │ │ Low Cost    │ │    │ │ No Timeout  │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Process     │ │    │ │ Kafka/SQS   │ │    │ │ Kafka/SQS   │ │
│ │ Chunks      │ │    │ │ Streaming   │ │    │ │ Streaming   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
{code}

h2. Components

h3. Compute Environment
* *Type*: MANAGED (AWS manages infrastructure)
* *Instance Types*: c5.4xlarge, c5.2xlarge, c5.xlarge
* *Capacity*: 0-256 vCPUs (auto-scaling)
* *Spot Instances*: 100% bid percentage for cost optimization
* *Subnets*: Private subnets for security

h3. Job Queue
* *State*: ENABLED for active processing
* *Priority*: 1 (highest priority)
* *Compute Environment*: Links to batch compute environment
* *Job Scheduling*: FIFO with priority-based ordering

h3. Job Definitions

h4. Validation Job
* *Purpose*: Validates entire files before processing
* *Resources*: 4 vCPUs, 8GB memory
* *Timeout*: 2 hours
* *Retries*: 3 attempts
* *Script*: batch_validator.py

h4. Processing Job
* *Purpose*: Processes individual chunks
* *Resources*: 4 vCPUs, 8GB memory
* *Timeout*: 2 hours
* *Retries*: 3 attempts
* *Script*: batch_processor.py
* *Environment Variables*:
** KAFKA_BROKERS
** KAFKA_TOPIC
** SQS_CORE_QUEUE
** RECORD_DESTINATION

h3. Launch Template
* *AMI*: Amazon Linux 2 ECS-Optimized
* *Instance Type*: c5.4xlarge
* *Storage*: 100GB GP3 encrypted volume
* *Monitoring*: Enhanced monitoring enabled
* *Security Groups*: Batch-specific security group

h3. CloudWatch Log Groups
* *Validation Logs*: /aws/batch/{prefix}-batch-validation
* *Processing Logs*: /aws/batch/{prefix}-batch-processing
* *Retention*: 30 days

h2. Configuration Files

The module uses JSON files for configuration, following the same pattern as the Lambda module:

{code:bash}
modules/
├── batch.hcl                    # Main Terragrunt configuration
├── batch-json/                  # JSON configuration files
│   ├── compute-environment.json # Compute environment configuration
│   ├── job-queue.json          # Job queue configuration
│   ├── batch-validation-job.json # Validation job definition
│   ├── batch-processing-job.json # Processing job definition
│   ├── launch-template.json    # EC2 launch template
│   └── log-groups.json         # CloudWatch log groups
├── batch_user_data.sh          # EC2 user data script
└── README-batch.md             # Documentation
{code}

h3. JSON Configuration Examples

h4. Compute Environment
{code:json}
{
  "name": "${PREFIX}-batch-compute",
  "type": "MANAGED",
  "compute_resources": {
    "type": "EC2",
    "max_vcpus": 256,
    "min_vcpus": 0,
    "desired_vcpus": 64,
    "instance_types": [
      "c5.4xlarge",
      "c5.2xlarge",
      "c5.xlarge"
    ],
    "subnets": ${SUBNETS},
    "security_group_ids": [
      "${SCM_BATCH_PROCESSOR_BATCH_SG}"
    ],
    "bid_percentage": 100
  }
}
{code}

h4. Job Definition
{code:json}
{
  "name": "${PREFIX}-batch-processing-job",
  "type": "container",
  "container_properties": {
    "image": "public.ecr.aws/lambda/python:3.9",
    "vcpus": 4,
    "memory": 8192,
    "command": [
      "/opt/batch-processing/batch_processor.py",
      "--chunk-id", "Ref::chunkId",
      "--start-index", "Ref::startIndex",
      "--end-index", "Ref::endIndex"
    ],
    "environment": [
      {
        "name": "KAFKA_BROKERS",
        "value": "${MSK_BROKERS}"
      },
      {
        "name": "RECORD_DESTINATION",
        "value": "${RECORD_DESTINATION}"
      }
    ]
  }
}
{code}

h2. Prerequisites

h3. IAM Roles
Create the following IAM roles in your iam-roles module:

{code:hcl}
# Service role for AWS Batch
scm-batch-processor-batch-role = {
  # AWSBatchServiceRole policy
  # S3, CloudWatch, ECS permissions
}

# Instance profile for EC2 instances
scm-batch-processor-batch-instance-role = {
  # S3, CloudWatch, MSK, SQS permissions
}
{code}

h3. Security Groups
Create a security group for batch processing:

{code:hcl}
scm-batch-processor-batch = {
  # Outbound rules for S3, CloudWatch, MSK, SQS
  # No inbound access required
}
{code}

h3. Modules Configuration
Add the batch module to your modules.hcl:

{code:hcl}
# In modules.hcl
module_urls = {
  batch_ext = "git::https://github.com/your-org/terraform-aws-batch.git"
}

# In version.hcl
module_versions = {
  batch_ext = "v1.0.0"
}
{code}

h2. Deployment

h3. 1. Deploy the Module
{code:bash}
cd terraform/step-function/real-code/modules
terragrunt plan
terragrunt apply
{code}

h3. 2. Update Step Function
The Step Function will automatically use AWS Batch for chunks >290K records:

{code:hcl}
# In your step-function.hcl
dependency "batch" {
  config_path = "../batch"
}

# The Step Function will reference:
# - aws_batch_job_queue.batch_processing_queue.arn
# - aws_batch_job_definition.batch_processing_job.arn
# - aws_batch_job_definition.batch_validation_job.arn
{code}

h3. 3. Monitor Jobs
{code:bash}
# View job queue
aws batch describe-job-queues --job-queues gss-dev-batch-queue

# View compute environment
aws batch describe-compute-environments --compute-environments gss-dev-batch-compute

# View job status
aws batch describe-jobs --jobs job-12345678-1234-1234-1234-123456789012
{code}

h2. Environment Variables

h3. Required Environment Variables
* *AWS_REGION*: AWS region
* *S3_BUCKET*: S3 bucket for data storage
* *KAFKA_BROKERS*: MSK broker endpoints
* *KAFKA_TOPIC*: Kafka topic name
* *SQS_CORE_QUEUE*: SQS queue URL
* *RECORD_DESTINATION*: "kafka" or "sqs_core"

h3. Optional Environment Variables
* *BATCH_PROCESSING_THRESHOLD*: Record threshold for Batch vs Lambda (default: 290000)

h2. Cost Optimization

h3. Spot Instances
* Uses 100% spot instances for cost savings
* Automatic fallback to on-demand if needed
* ~70% cost reduction compared to on-demand

h3. Instance Sizing
* c5.4xlarge: High CPU, cost-effective for processing
* Auto-scaling: Scales down to 0 when not in use
* Pay only for what you use

h3. Storage
* GP3 volumes: Better performance, lower cost
* 100GB default: Adjust based on your data size
* Encrypted at rest for security

h2. Monitoring and Logging

h3. CloudWatch Logs
* *Validation Logs*: /aws/batch/{prefix}-batch-validation
* *Processing Logs*: /aws/batch/{prefix}-batch-processing
* *Retention*: 30 days

h3. Metrics
* Job success/failure rates
* Processing time per chunk
* Resource utilization
* Cost metrics

h2. Troubleshooting

h3. Common Issues

h4. Job Stuck in RUNNABLE
{code:bash}
# Check compute environment status
aws batch describe-compute-environments --compute-environments gss-dev-batch-compute

# Check for capacity issues
aws batch describe-job-queues --job-queues gss-dev-batch-queue
{code}

h4. Job Failing
{code:bash}
# Check job logs
aws logs describe-log-streams --log-group-name "/aws/batch/gss-dev-batch-processing"

# Get job details
aws batch describe-jobs --jobs job-12345678-1234-1234-1234-123456789012
{code}

h4. Permission Issues
{code:bash}
# Verify IAM roles
aws iam get-role --role-name gss-dev-scm-batch-processor-batch-role
aws iam get-instance-profile --instance-profile-name gss-dev-scm-batch-processor-batch-instance-role
{code}

h3. Debug Commands
{code:bash}
# List all batch resources
aws batch describe-job-definitions
aws batch describe-job-queues
aws batch describe-compute-environments

# Monitor job progress
aws batch list-jobs --job-queue gss-dev-batch-queue --job-status RUNNING
{code}

h2. Security

h3. Network Security
* Instances run in private subnets
* Security group restricts outbound traffic
* No inbound access required

h3. Data Security
* EBS volumes encrypted at rest
* S3 access via IAM roles
* MSK authentication via IAM

h3. IAM Security
* Least privilege principle
* Separate roles for service and instances
* No long-term credentials

h2. Scaling

h3. Automatic Scaling
* Scales from 0 to 256 vCPUs based on demand
* Spot instances for cost optimization
* Automatic instance termination when idle

h3. Manual Scaling
{code:bash}
# Update compute environment
aws batch update-compute-environment \
  --compute-environment gss-dev-batch-compute \
  --compute-resources desiredVcpus=128
{code}

h2. Integration with Step Function

The Step Function automatically routes chunks based on size:

{code:json}
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
{code}

This ensures optimal resource usage and cost efficiency.

h2. Performance Comparison

|| Metric || Lambda || AWS Batch ||
| Startup Time | ~100-500ms | ~2-5 minutes |
| Cost (60M records) | ~$15 | ~$26.40 |
| Memory Limit | 15GB | Unlimited |
| Timeout | 15 minutes | Unlimited |
| Scalability | Automatic | Manual configuration |

h2. Best Practices

h3. Chunk Sizing
* Use 290K records as the threshold
* Larger chunks reduce overhead
* Smaller chunks provide better error isolation

h3. Resource Allocation
* Start with 4 vCPUs, 8GB memory
* Monitor and adjust based on performance
* Use spot instances for cost optimization

h3. Monitoring
* Set up CloudWatch alarms for job failures
* Monitor resource utilization
* Track cost metrics

h2. Support

For issues or questions:
# Check CloudWatch logs for detailed error messages
# Review IAM permissions and security group rules
# Verify network connectivity to S3, MSK, and SQS
# Check compute environment capacity and scaling

h2. Related Documentation

* [Lambda Module Documentation|https://confluence.example.com/lambda-module]
* [Step Function Module Documentation|https://confluence.example.com/step-function-module]
* [AWS Batch Best Practices|https://docs.aws.amazon.com/batch/latest/userguide/best-practices.html]
* [Cost Optimization Guide|https://docs.aws.amazon.com/batch/latest/userguide/cost-optimization.html] 