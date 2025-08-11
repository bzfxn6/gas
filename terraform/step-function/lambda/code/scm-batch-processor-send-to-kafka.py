import json
import boto3
import logging
from kafka import KafkaProducer
from kafka.errors import KafkaError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')

def validate_input(event):
    """Validate input parameters"""
    required_fields = ['batchId', 'customerId', 'tenantId', 'deployment']
    missing_fields = [field for field in required_fields if not event.get(field)]
    if missing_fields:
        return f"Missing required fields: {', '.join(missing_fields)}"
    return None

def lambda_handler(event, context):
    """Send batch completion notification to Kafka - lightweight summary only"""
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
        
        logger.info(f"Sending batch completion notification to Kafka for batch {batch_id}")
        logger.info(f"Records processed: {total_records_processed:,}, Errors: {total_errors}")

        # Initialize Kafka producer
        try:
            producer = KafkaProducer(
                bootstrap_servers=event.get('mskBrokers', []),
                value_serializer=lambda v: json.dumps(v).encode('utf-8'),
                security_protocol='SASL_SSL',
                sasl_mechanism='AWS_MSK_IAM',
                sasl_plain_username='',
                sasl_plain_password=''
            )
        except Exception as e:
            return create_error(f"Error initializing Kafka producer: {str(e)}", batch_id, customer_id, tenant_id, deployment)

        # Create batch completion notification message
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
                'recordsPerSecond': total_records_processed / processing_time if processing_time > 0 else 0,
                'recordsSentToKafka': total_records_processed - total_errors  # All valid records were sent to Kafka
            },
            'resultLocation': {
                'bucket': event.get('bucket', ''),
                'key': final_result_key
            },
            'timestamp': event.get('completionTime', ''),
            'metadata': {
                'source': 'batch-processing-workflow',
                'version': '1.0',
                'note': 'Individual records were sent to Kafka during processing (exclusive routing)'
            }
        }

        # Send notification to Kafka
        try:
            future = producer.send(event.get('mskTopic', 'batch-notifications'), notification_message)
            future.get(timeout=30)  # Wait for send to complete
            
            logger.info(f"Successfully sent batch completion notification to Kafka for batch {batch_id}")
            
        except KafkaError as ke:
            error_msg = f"Kafka error sending notification: {str(ke)}"
            logger.error(error_msg)
            return create_error(error_msg, batch_id, customer_id, tenant_id, deployment)
        except Exception as e:
            error_msg = f"Error sending notification to Kafka: {str(e)}"
            logger.error(error_msg)
            return create_error(error_msg, batch_id, customer_id, tenant_id, deployment)
        finally:
            producer.close()

        # Return success response
        return {
            'batchId': batch_id,
            'customerId': customer_id,
            'tenantId': tenant_id,
            'deployment': deployment,
            'snapshotId': snapshot_id,
            'batchStatus': 'BATCH_COMPLETION_NOTIFICATION_SENT',
            'kafkaMessage': notification_message,
            'timestamp': event.get('completionTime', '')
        }

    except Exception as e:
        logger.error(f"Unexpected error in Kafka notification: {str(e)}")
        return create_error(f"Kafka notification failed: {str(e)}", 
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