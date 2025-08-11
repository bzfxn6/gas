import os
import boto3
import json
import socket
import time
import logging
from kafka import KafkaProducer
from kafka.errors import KafkaError
from aws_msk_iam_sasl_signer import MSKAuthTokenProvider
from botocore.exceptions import ClientError
 
# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
 
s3_client = boto3.client('s3')
 
class MSKTokenProvider():
    def token(self):
        try:
            token, _ = MSKAuthTokenProvider.generate_auth_token('eu-west-2')
            logger.info("Successfully generated MSK token")
            return token
        except Exception as e:
            logger.error(f"Failed to generate MSK token: {str(e)}")
            return create_error(f"Failed to generate MSK token: {str(e)}")
 
tp = MSKTokenProvider()
 
def lambda_handler(event, context):
    start_time = time.time()
    error_messages = []
    records_processed = 0
    records_failed = 0
 
    try:
        # Validate input
        if not all(k in event for k in ['batchId', 'customerId', 'Bucket', 'Key']):
            return create_error("Missing required fields in event")
 
        batch_id = event['batchId']  # Retrieved from Step Function input
        customer_id = event['customerId']  # Retrieved from Step Function input
 
        # Kafka configuration
        logging.basicConfig(level=logging.DEBUG)
        brokers = json.loads(os.environ.get('msk_brokers'))
        if not brokers:
            return create_error("No MSK brokers configured")
 
        producer = KafkaProducer(
            bootstrap_servers=brokers,
            security_protocol='SASL_SSL',
            sasl_mechanism='OAUTHBEARER',
            sasl_oauth_token_provider=tp,
            client_id=socket.gethostname(),
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
 
        # Read the file from S3
        try:
            response = s3_client.get_object(Bucket=event['Bucket'], Key=event['Key'])
            json_data = response['Body'].read().decode('utf-8')
            records = json.loads(json_data)
            logger.info(f"Successfully read {len(records)} records from S3")
 
        except ClientError as e:
            logger.error(f"Failed to read from S3: {str(e)}")
            logger.info(f"METRIC|S3ReadFailure|1|{batch_id}")
            return create_error(f"Failed to read from S3: {str(e)}")
 
        # Process records and send to Kafka
        # Get topic from environment variable
        topic = os.environ.get('msk_topic')
        if not topic:
           return create_error("No MSK topic configured in environment variables")
 
        for record in records:
            try:
                if 'gssId' not in record:
                    return create_error(f"Record missing gssId")
 
                #Send the message to the Kafka topic with headers
                send_record = producer.send(
                    topic,  # The Kafka topic to send messages to
                    value=record,
                    headers=[
                        ('batchId', batch_id.encode('utf-8')),                                  # Add batchId to headers
                        ('correlationId', record.get('gssId', 'key not found').encode('utf-8')) # Add gssId to headers
                    ]
                )
 
                # Wait for message to be delivered
                send_record.get(timeout=10)
                records_processed += 1
                logger.info(f"Successfully processed record with gssId: {record['gssId']}")
 
            except Exception as e:
                error_msg = f"Failed to process record {record.get('gssId', 'unknown')}: {str(e)}"
                logger.error(error_msg)
                error_messages.append(error_msg)
                records_failed += 1
 
        producer.flush()  # Ensure the message is sent
 
    except Exception as e:
        logger.error(f"Fatal error in lambda execution: {str(e)}")
        logger.info(f"METRIC|LambdaExecutionFailure|1|{batch_id}")
        raise
 
    finally:
        # Publish metrics
        execution_time = time.time() - start_time
        logger.info(f"METRIC|ProcessingTime|{execution_time}|{batch_id}")
        logger.info(f"METRIC|RecordsProcessed|{records_processed}|{batch_id}")
        logger.info(f"METRIC|RecordsFailed|{records_failed}|{batch_id}")
 
        if producer:
            producer.close()
 
    # Final response based on success or failure of message production
    if error_messages:
        return {
            "batchStatus": "SUBMISSION_FAILED",
            'batchId': batch_id,
            'customerId': customer_id,
            'errors': error_messages
        }
 
    return {
        'status': 'SUCCESS',
        'batchId': batch_id,
        'customerId': customer_id
    }
 
def create_error(error_message, batch_id="unknown", customer_id="unknown", tenant_id="unknown", records_failed=0, records_processed=0, error_messages=[]):
    """Helper function to return properly formatted errors for Step Functions."""
    error_data = {
        "errorMessage": error_message,
        "batchId": batch_id,
        "customerId": customer_id,
        "batchStatus": "SUBMISSION_FAILED",
        'errorCount': records_failed,
        'processedCount': records_processed
    }
    return error_data
 
 