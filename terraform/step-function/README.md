# Enhanced Batch Processing Step Function

This enhanced Step Function is designed to efficiently process large datasets containing up to 60,000,000 records using a combination of AWS Lambda and AWS Batch for optimal performance and cost-effectiveness.

## Architecture Overview

The system uses a hybrid approach:
- **AWS Lambda**: For smaller chunks and orchestration
- **AWS Batch**: For heavy processing workloads (chunks > 1M records)
- **Parallel Processing**: Up to 50 concurrent chunks
- **S3**: For data storage and result aggregation

## Key Features

### 🚀 High Performance
- **Parallel Processing**: Up to 50 chunks processed simultaneously
- **Hybrid Processing**: Lambda for small chunks, AWS Batch for large chunks
- **Optimized Chunking**: 500K records per chunk for 60M total = 120 chunks
- **Estimated Processing Time**: ~2-3 hours for 60M records

### 📊 Monitoring & Visibility
- Real-time progress tracking
- Comprehensive error reporting
- Performance metrics and analytics
- CloudWatch integration for monitoring

### 🔄 Fault Tolerance
- Automatic retry mechanisms
- Chunk-level error handling
- Partial success handling
- Continuation support for interrupted processing

### 💰 Cost Optimization
- Right-sized compute resources
- Efficient memory allocation
- Pay-per-use pricing model
- Resource auto-scaling

## Step Function Workflow

```
InitializeBatchProcessing → ValidateBatchConfig → CalculateChunks → ProcessChunksInParallel → AggregateResults → SendToKafka/SQS
```

### Detailed Flow:

1. **InitializeBatchProcessing**: Validates input and prepares batch configuration
2. **ValidateBatchConfig**: Ensures all required parameters are present
3. **CalculateChunks**: Splits 60M records into optimal chunks
4. **ProcessChunksInParallel**: 
   - Uses Map state for parallel processing
   - Routes chunks to Lambda or AWS Batch based on size
   - Monitors job status and handles failures
5. **AggregateResults**: Combines all chunk results into final output
6. **SendToKafka/SQS**: Delivers results to downstream systems

## Configuration

### Environment Variables

```hcl
# Batch Processing Configuration
batch_processing_threshold = 1000000  # Use AWS Batch for chunks > 1M records
max_records_per_chunk     = 500000    # 500K records per chunk
max_concurrent_chunks     = 50        # Parallel processing limit

# AWS Batch Configuration
batch_max_vcpus          = 256        # Maximum vCPUs
batch_desired_vcpus      = 64         # Desired vCPUs
batch_job_vcpus          = 4          # vCPUs per job
batch_job_memory         = 8192       # Memory per job (MB)

# Performance Tuning
lambda_timeout           = 900        # 15 minutes
lambda_memory           = 10240       # 10GB max
estimated_processing_time_per_record = 0.005  # 5ms per record
```

### Lambda Functions

1. **scm-batch-processor-read-s3**: Initializes batch processing
2. **scm-batch-processor-calculate-chunks**: Creates optimal chunk definitions
3. **scm-batch-processor-update-records**: Processes individual chunks
4. **scm-batch-processor-aggregate-results**: Combines all results
5. **scm-batch-processor-send-to-kafka**: Sends to Kafka
6. **scm-batch-processor-send-to-sqs-core**: Sends to SQS Core

## Performance Estimates

### For 60,000,000 Records:

| Metric | Value |
|--------|-------|
| Total Chunks | 120 |
| Chunk Size | 500,000 records |
| Concurrent Processing | 50 chunks |
| Estimated Processing Time | 2-3 hours |
| Records per Second | ~8,000 |
| Memory Usage | ~25GB total |
| Cost Estimate | $50-100 |

### Processing Rates:

- **Small Chunks (Lambda)**: 10,000 records/second
- **Large Chunks (AWS Batch)**: 15,000 records/second
- **Overall Average**: 8,000 records/second

## Deployment

### Prerequisites

1. **VPC Configuration**: Subnet IDs and Security Group IDs for AWS Batch
2. **S3 Bucket**: For data storage and results
3. **IAM Roles**: Proper permissions for Lambda, Step Functions, and AWS Batch
4. **DynamoDB Table**: For record storage (if applicable)

### Terraform Deployment

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="s3_bucket_name=your-bucket-name" \
               -var="batch_subnet_ids=[subnet-123,subnet-456]" \
               -var="batch_security_group_ids=[sg-123]"

# Deploy
terraform apply -var="s3_bucket_name=your-bucket-name" \
                -var="batch_subnet_ids=[subnet-123,subnet-456]" \
                -var="batch_security_group_ids=[sg-123]"
```

### Input Parameters

```json
{
  "bucket": "your-data-bucket",
  "file": "path/to/60m-records.json",
  "customerId": "customer123",
  "tenantId": "tenant456",
  "batchId": "batch-789",
  "deployment": "WORKSPACE",
  "snapshotId": "snapshot-001"
}
```

## Monitoring

### CloudWatch Metrics

- **Step Function Execution Time**
- **Lambda Duration and Errors**
- **AWS Batch Job Status**
- **S3 Object Operations**
- **Processing Progress**

### Logs

- **Step Function Execution Logs**
- **Lambda Function Logs**
- **AWS Batch Job Logs**
- **Custom Application Logs**

### Dashboards

Pre-configured CloudWatch dashboards provide:
- Real-time processing status
- Performance metrics
- Error rates and types
- Resource utilization

## Error Handling

### Chunk-Level Errors
- Individual chunk failures don't stop the entire batch
- Failed chunks are retried automatically
- Error details are captured and reported

### Batch-Level Errors
- Comprehensive error reporting
- Partial success handling
- Recovery mechanisms for interrupted processing

### Common Error Scenarios

1. **Lambda Timeout**: Chunk too large, route to AWS Batch
2. **Memory Issues**: Reduce chunk size or increase memory
3. **Network Issues**: Automatic retry with exponential backoff
4. **S3 Errors**: Retry with different strategies

## Cost Optimization

### Resource Sizing
- **Lambda**: Right-sized memory and timeout
- **AWS Batch**: Spot instances for cost savings
- **S3**: Intelligent tiering for storage costs

### Performance Tuning
- **Chunk Size**: Optimized for processing efficiency
- **Concurrency**: Balanced for cost and performance
- **Memory Allocation**: Based on actual usage patterns

## Security

### IAM Permissions
- Least privilege access
- Role-based permissions
- Temporary credentials

### Data Protection
- Encryption at rest and in transit
- VPC isolation for AWS Batch
- Secure parameter handling

## Troubleshooting

### Common Issues

1. **Chunk Processing Failures**
   ```bash
   # Check chunk status
   aws stepfunctions get-execution-history --execution-arn <arn>
   ```

2. **AWS Batch Job Failures**
   ```bash
   # Check job status
   aws batch describe-jobs --jobs <job-id>
   ```

3. **Memory Issues**
   - Increase Lambda memory allocation
   - Reduce chunk size
   - Use AWS Batch for large chunks

4. **Timeout Issues**
   - Increase Lambda timeout
   - Route to AWS Batch
   - Optimize processing logic

### Debug Commands

```bash
# Check Step Function status
aws stepfunctions describe-execution --execution-arn <arn>

# Monitor Lambda logs
aws logs tail /aws/lambda/scm-batch-processor-calculate-chunks

# Check S3 objects
aws s3 ls s3://your-bucket/results/batch-id/

# Monitor AWS Batch
aws batch list-jobs --job-queue <queue-name>
```

## Best Practices

### Performance
1. **Monitor Resource Usage**: Use CloudWatch to track performance
2. **Optimize Chunk Size**: Balance between memory and processing time
3. **Use Spot Instances**: For AWS Batch to reduce costs
4. **Implement Caching**: For frequently accessed data

### Reliability
1. **Implement Retries**: With exponential backoff
2. **Handle Partial Failures**: Continue processing successful chunks
3. **Monitor Progress**: Real-time status updates
4. **Backup Results**: Store intermediate results in S3

### Cost Management
1. **Right-size Resources**: Based on actual usage
2. **Use Spot Instances**: For non-critical workloads
3. **Monitor Costs**: Set up billing alerts
4. **Clean Up Resources**: Remove temporary files

## Support

For issues or questions:
1. Check CloudWatch logs for detailed error information
2. Review Step Function execution history
3. Monitor AWS Batch job status
4. Contact the development team with execution ARNs and error details

## Future Enhancements

- **Machine Learning Integration**: For intelligent chunk sizing
- **Real-time Streaming**: For live data processing
- **Advanced Analytics**: For processing insights
- **Auto-scaling**: Based on workload patterns 