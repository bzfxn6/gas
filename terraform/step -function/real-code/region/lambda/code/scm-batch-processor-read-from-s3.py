import json
import boto3
import time
import logging
from botocore.exceptions import ClientError
 
# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
 
s3_client = boto3.client('s3')
 
def lambda_handler(event, context):
    batch_id = "00000000-0000-0000-0000-000000000000"  # Default if extraction fails
 
    try:
        # Get bucket and key from event
        bucket = event.get('detail', {}).get('bucket', {}).get('name')
        key = event.get('detail', {}).get('object', {}).get('key')
 
        if not bucket or not key:
            return create_error("Missing bucket or key in event", {'batchId': '00000000-0000-0000-0000-000000000000'})
 
        # Read file from S3 and parse JSON
        try:
            response = s3_client.get_object(Bucket=bucket, Key=key)
            content = response['Body'].read().decode('utf-8')
            json_data = json.loads(content)
 
            # Extract batch_id early and persist it
            batch_id = json_data.get("batchId", "00000000-0000-0000-0000-000000000000")
            customer_id = json_data.get("customerId", "unknown")
            tenant_id = json_data.get("tenantId", "unknown")
            snapshot_id = json_data.get("snapshotId", "unknown")
            deployment = json_data.get("deployment", "unknown")
            file = json_data.get("file")
 
        except s3_client.exceptions.NoSuchKey:
            return create_error(f"File {key} not found in bucket {bucket}", {'batchId': '00000000-0000-0000-0000-000000000000'})
        except s3_client.exceptions.NoSuchBucket:
            return create_error(f"Bucket {bucket} does not exist", {'batchId': '00000000-0000-0000-0000-000000000000'})
        except json.JSONDecodeError:
            return create_error(f"Invalid JSON content in file {key}", {'batchId': '00000000-0000-0000-0000-000000000000'})
        except Exception as e:
            return create_error(f"Error reading file: {str(e)}", {'batchId': '00000000-0000-0000-0000-000000000000'})
 
        # Check required fields
        missing_fields = []
        if not customer_id:
            missing_fields.append('customerId')
        if not tenant_id:
            missing_fields.append('tenantId')
        if not deployment:
            missing_fields.append('deployment')
        if deployment == 'WORKSPACE' and not snapshot_id:
            missing_fields.append('snapshotId')
        if not file:
            missing_fields.append('file')
 
        if missing_fields:
            return create_error(f"Missing required fields: {', '.join(missing_fields)}", batch_id, customer_id, tenant_id, deployment)
 
        logger.info(f"Successfully extracted fields from file {key}")
        logger.info(f"BatchId: {batch_id}, CustomerId: {customer_id}, TenantId: {tenant_id}, Deployment: {deployment}, SnasphotId: {snapshot_id}")
 
        return {
            'batchId': batch_id,
            'customerId': customer_id,
            'tenantId': tenant_id,
            'snapshotId': snapshot_id,
            'deployment': deployment,
            'file': file,
            'bucket': bucket,
            "batchStatus":"PASS"
        }
 
    except Exception as e:
            logger.error(f"Unexpected error: {str(e)}")
            return create_error(f"Unexpected error: {str(e)}", batch_id)
 
def create_error(error_message, batch_id="unknown", customer_id="unknown", tenant_id="unknown", deployment="unknown"):
    """Helper function to return properly formatted errors for Step Functions."""
    error_data = {
        "errorMessage": error_message,
        "batchId": batch_id,
        "customerId": customer_id,
        "tenantId": tenant_id,
        'deployment': deployment,
        "batchStatus": "SUBMISSION_FAILED"
    }
    return error_data