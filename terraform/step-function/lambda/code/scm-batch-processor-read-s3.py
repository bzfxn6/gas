import json
import boto3
import logging
from datetime import datetime

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')

def validate_input(event):
    """Validate input parameters"""
    required_fields = ['bucket', 'file', 'customerId', 'tenantId', 'batchId']
    missing_fields = [field for field in required_fields if not event.get(field)]
    if missing_fields:
        return f"Missing required fields: {', '.join(missing_fields)}"
    return None

def check_file_size(bucket, file):
    """Check file size and estimate records"""
    try:
        head = s3_client.head_object(Bucket=bucket, Key=file)
        file_size = head['ContentLength']
        
        # Estimate records based on file size (rough estimate: 1KB per record)
        estimated_records = max(1000000, file_size // 1024)
        
        logger.info(f"File size: {file_size:,} bytes, estimated records: {estimated_records:,}")
        return file_size, estimated_records
        
    except Exception as e:
        logger.error(f"Error checking file size: {str(e)}")
        return None, None

def get_validation_errors(bucket, batch_id):
    """Retrieve validation errors from S3"""
    try:
        validation_key = f"validation/{batch_id}/validation-results.json"
        response = s3_client.get_object(Bucket=bucket, Key=validation_key)
        validation_results = json.loads(response['Body'].read().decode('utf-8'))
        
        return {
            'errorMessage': validation_results.get('errorMessage', 'Validation failed'),
            'validationErrors': validation_results.get('validationErrors', []),
            'validationSummary': validation_results.get('validationSummary', {})
        }
        
    except Exception as e:
        logger.error(f"Error retrieving validation errors: {str(e)}")
        return {
            'errorMessage': f"Error retrieving validation results: {str(e)}",
            'validationErrors': [],
            'validationSummary': {}
        }

def get_validation_results(bucket, batch_id):
    """Retrieve validation results from S3"""
    try:
        validation_key = f"validation/{batch_id}/validation-results.json"
        response = s3_client.get_object(Bucket=bucket, Key=validation_key)
        validation_results = json.loads(response['Body'].read().decode('utf-8'))
        
        logger.info(f"Retrieved validation results for batch {batch_id}")
        logger.info(f"Validation status: {validation_results.get('status')}")
        logger.info(f"Batch status: {validation_results.get('batchStatus')}")
        
        if validation_results.get('validationSummary', {}).get('criticalIssues'):
            logger.warning(f"Critical issues detected: {validation_results['validationSummary']['criticalIssues']}")
        
        return validation_results
        
    except Exception as e:
        logger.error(f"Error retrieving validation results: {str(e)}")
        return {
            'status': 'FAILED',
            'batchStatus': 'VALIDATION_FAILED',
            'errorMessage': f"Error retrieving validation results: {str(e)}",
            'validationSummary': {
                'criticalIssues': [f"Failed to retrieve validation results: {str(e)}"]
            }
        }

def lambda_handler(event, context):
    """Initialize batch processing or retrieve validation errors/results"""
    try:
        # Check if this is a validation error retrieval request
        if event.get('action') == 'getValidationErrors':
            bucket = event['bucket']
            batch_id = event['batchId']
            
            logger.info(f"Retrieving validation errors for batch {batch_id}")
            return get_validation_errors(bucket, batch_id)
        
        # Check if this is a validation results retrieval request
        if event.get('action') == 'getValidationResults':
            bucket = event['bucket']
            batch_id = event['batchId']
            
            logger.info(f"Retrieving validation results for batch {batch_id}")
            return get_validation_results(bucket, batch_id)

        # Normal initialization flow
        error = validate_input(event)
        if error:
            return create_error(error, event.get('batchId', 'unknown'))

        bucket = event['bucket']
        file = event['file']
        customer_id = event['customerId']
        tenant_id = event['tenantId']
        batch_id = event['batchId']
        snapshot_id = event.get('snapshotId')
        deployment = event.get('deployment', 'WORKSPACE')
        
        logger.info(f"Initializing batch processing for {file} from bucket {bucket}")
        logger.info(f"BatchId: {batch_id}, CustomerId: {customer_id}, TenantId: {tenant_id}")

        # Check file size and estimate records
        file_size, estimated_records = check_file_size(bucket, file)
        if file_size is None:
            return create_error("Error checking file size", batch_id, customer_id, tenant_id, deployment)

        # Get target total records from input or use estimated
        target_total_records = event.get('targetTotalRecords', estimated_records)
        
        # Prepare batch configuration
        batch_config = {
            'batchId': batch_id,
            'customerId': customer_id,
            'tenantId': tenant_id,
            'snapshotId': snapshot_id,
            'deployment': deployment,
            'bucket': bucket,
            'file': file,
            'targetTotalRecords': target_total_records,
            'estimatedFileSize': file_size,
            'estimatedRecords': estimated_records,
            'initializedAt': datetime.now().isoformat()
        }
        
        logger.info(f"Batch configuration prepared: {json.dumps(batch_config, indent=2)}")
        return batch_config
        
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        return create_error(f"Initialization error: {str(e)}", event.get('batchId', 'unknown'))

def create_error(error_message, batch_id="unknown", customer_id="unknown", tenant_id="unknown", deployment="unknown"):
    """Create error response"""
    return {
        'batchId': batch_id,
        'customerId': customer_id,
        'tenantId': tenant_id,
        'deployment': deployment,
        'batchStatus': 'SUBMISSION_FAILED',
        'errorMessage': error_message,
        'errorTime': datetime.now().isoformat()
    } 