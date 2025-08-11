import json
import boto3
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs_client = boto3.client('sqs')

def validate_input(event):
    """Validate input parameters"""
    required_fields = ['batchId', 'customerId', 'tenantId', 'deployment']
    missing_fields = [field for field in required_fields if not event.get(field)]
    if missing_fields:
        return f"Missing required fields: {', '.join(missing_fields)}"
    return None

def lambda_handler(event, context):
    """Send batch completion notification to SQS Core - lightweight summary only"""
    try:
        # Validate input parameters
        error = validate_input(event)
        if error:
            return create_error(error, event.get('batchId', 'unknown'))

        batch_id = event['batchId']
        customer_id = event['customerId']
        tenant_id = event['tenantId']
        deployment = event.get('deployment', 'WORKSPACE')
        snapshot_id = event.get('snapshotId')
        
        # Get summary information from aggregated results
        total_records_processed = event.get('totalRecordsProcessed', 0)
        total_errors = event.get('totalErrors', 0)
        processing_time = event.get('processingTime', 0)
        final_result_key = event.get('finalResultKey', '')
        
        logger.info(f"Sending batch completion notification to SQS Core for batch {batch_id}")
        logger.info(f"Records processed: {total_records_processed:,}, Errors: {total_errors}")

        # Create summary notification message
        notification_message = {
            'type': 'BATCH_COMPLETION_NOTIFICATION',
            'batchId': batch_id,
            'customerId': customer_id,
            'tenantId': tenant_id,
            'deployment': deployment,
            'snapshotId': snapshot_id,
            'status': 'COMPLETED',
            'summary': {
                'totalRecordsProcessed': total_records_processed,
                'totalErrors': total_errors,
                'successRate': ((total_records_processed - total_errors) / total_records_processed * 100) if total_records_processed > 0 else 0,
                'processingTime': processing_time,
                'recordsPerSecond': total_records_processed / processing_time if processing_time > 0 else 0
            },
            'resultLocation': {
                'bucket': event.get('bucket', ''),
                'key': final_result_key
            },
            'timestamp': event.get('completionTime', ''),
            'metadata': {
                'source': 'batch-processing-workflow',
                'version': '1.0'
            }
        }

        # Send notification to SQS Core
        try:
            response = sqs_client.send_message(
                QueueUrl=event.get('sqsCoreQueue', ''),
                MessageBody=json.dumps(notification_message)
            )
            
            logger.info(f"Successfully sent batch completion notification to SQS Core for batch {batch_id}")
            logger.info(f"SQS Message ID: {response.get('MessageId', 'unknown')}")
            
        except Exception as e:
            error_msg = f"Error sending notification to SQS Core: {str(e)}"
            logger.error(error_msg)
            return create_error(error_msg, batch_id, customer_id, tenant_id, deployment)

        # Return success response
        return {
            'batchId': batch_id,
            'customerId': customer_id,
            'tenantId': tenant_id,
            'deployment': deployment,
            'snapshotId': snapshot_id,
            'batchStatus': 'SQS_CORE_NOTIFICATION_SENT',
            'sqsMessage': notification_message,
            'sqsMessageId': response.get('MessageId', ''),
            'timestamp': event.get('completionTime', '')
        }

    except Exception as e:
        logger.error(f"Unexpected error in SQS Core notification: {str(e)}")
        return create_error(f"SQS Core notification failed: {str(e)}", 
                          event.get('batchId', 'unknown'),
                          event.get('customerId', 'unknown'),
                          event.get('tenantId', 'unknown'),
                          event.get('deployment', 'unknown'))

def create_error(error_message, batch_id="unknown", customer_id="unknown", tenant_id="unknown", deployment="unknown"):
    """Create error response"""
    return {
        'batchId': batch_id,
        'customerId': customer_id,
        'tenantId': tenant_id,
        'deployment': deployment,
        'batchStatus': 'SUBMISSION_FAILED',
        'errorMessage': error_message,
        'errorTime': '2024-01-01T00:00:00Z'  # Placeholder timestamp
    } 