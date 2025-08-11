import json
import boto3
import uuid
import logging
import time
import os
from datetime import datetime
from typing import Dict, List, Any, Optional
from botocore.exceptions import ClientError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3 = boto3.client('s3')

def transform_record(record: Dict[str, Any], customer_id: str, tenant_id: str) -> Dict[str, Any]:
    """Apply business logic transformations to a record (same as batch processor)"""
    # Add processing timestamp
    record['processedAt'] = datetime.now().isoformat()
    
    # Update customer and tenant IDs
    record['customerId'] = customer_id
    record['tenantId'] = tenant_id
    
    # Replace 'gssId' with a new UUID
    if 'gssId' in record:
        record['gssId'] = str(uuid.uuid4())
    
    # Generate new ID if needed
    if 'id' in record:
        record['originalId'] = record['id']
        record['id'] = f"{customer_id}_{tenant_id}_{int(time.time() * 1000)}"
    
    return record

def send_records_to_kafka(records: List[Dict[str, Any]], chunk_id: str, start_index: int, 
                         customer_id: str, tenant_id: str, batch_id: str, 
                         kafka_brokers: List[str], kafka_topic: str) -> Dict[str, int]:
    """Send records to Kafka (simplified version for Lambda)"""
    try:
        from kafka import KafkaProducer
        from kafka.errors import KafkaError
        
        producer = KafkaProducer(
            bootstrap_servers=kafka_brokers,
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            security_protocol='SASL_SSL',
            sasl_mechanism='AWS_MSK_IAM',
            sasl_plain_username='',
            sasl_plain_password='',
            batch_size=16384,
            linger_ms=10,
            compression_type='gzip'
        )
        
        success_count = 0
        error_count = 0
        
        for i, record in enumerate(records):
            try:
                # Add metadata to the record
                kafka_message = {
                    'record': record,
                    'metadata': {
                        'batchId': batch_id,
                        'chunkId': chunk_id,
                        'recordIndex': start_index + i,
                        'customerId': customer_id,
                        'tenantId': tenant_id,
                        'processedAt': datetime.now().isoformat(),
                        'source': 'lambda-processor',
                        'destination': 'kafka'
                    }
                }
                
                future = producer.send(kafka_topic, kafka_message)
                success_count += 1
                
            except Exception as e:
                error_count += 1
                logger.error(f"Kafka send error for record {i}: {str(e)}")
        
        # Flush producer
        producer.flush(timeout=30)
        producer.close()
        
        return {'success': success_count, 'errors': error_count}
        
    except Exception as e:
        logger.error(f"Failed to initialize Kafka producer: {str(e)}")
        return {'success': 0, 'errors': len(records)}

def send_records_to_sqs(records: List[Dict[str, Any]], chunk_id: str, start_index: int,
                       customer_id: str, tenant_id: str, batch_id: str,
                       sqs_queue_url: str) -> Dict[str, int]:
    """Send records to SQS Core"""
    try:
        sqs_client = boto3.client('sqs')
        
        success_count = 0
        error_count = 0
        
        for i, record in enumerate(records):
            try:
                # Create SQS message
                sqs_message = {
                    'record': record,
                    'metadata': {
                        'batchId': batch_id,
                        'chunkId': chunk_id,
                        'recordIndex': start_index + i,
                        'customerId': customer_id,
                        'tenantId': tenant_id,
                        'processedAt': datetime.now().isoformat(),
                        'source': 'lambda-processor',
                        'destination': 'sqs-core'
                    }
                }
                
                response = sqs_client.send_message(
                    QueueUrl=sqs_queue_url,
                    MessageBody=json.dumps(sqs_message)
                )
                success_count += 1
                
            except Exception as e:
                error_count += 1
                logger.error(f"SQS send error for record {i}: {str(e)}")
        
        return {'success': success_count, 'errors': error_count}
        
    except Exception as e:
        logger.error(f"Failed to initialize SQS client: {str(e)}")
        return {'success': 0, 'errors': len(records)}

def process_chunk(event: Dict[str, Any]) -> Dict[str, Any]:
    """Process a chunk of records using Lambda (for smaller chunks)"""
    try:
        start_time = time.time()
        
        # Extract parameters
        chunk_id = event['chunkId']
        start_index = event['startIndex']
        end_index = event['endIndex']
        bucket = event['bucket']
        file_key = event['file']
        customer_id = event['customerId']
        tenant_id = event['tenantId']
        batch_id = event['batchId']
        destination = event.get('destination', 'kafka').lower()
        
        # Configuration from environment
        kafka_brokers = os.environ.get('KAFKA_BROKERS', '').split(',')
        kafka_topic = os.environ.get('KAFKA_TOPIC', 'processed-records')
        sqs_core_queue = os.environ.get('SQS_CORE_QUEUE', '')
        
        logger.info(f"Processing chunk {chunk_id}: records {start_index:,} to {end_index:,}")
        logger.info(f"Destination: {destination}")
        
        # Download chunk data from S3
        chunk_key = f"chunks/{batch_id}/{chunk_id}.json"
        response = s3.get_object(Bucket=bucket, Key=chunk_key)
        records = json.loads(response['Body'].read().decode('utf-8'))
        
        # Process all records first
        processed_records = []
        processing_errors = []
        
        for i, record in enumerate(records):
            try:
                # Apply business logic transformations
                processed_record = transform_record(record, customer_id, tenant_id)
                processed_records.append(processed_record)
                
            except Exception as e:
                processing_errors.append({
                    'record_index': i,
                    'error': str(e),
                    'record': record
                })
        
        # Send processed records to configured destination
        kafka_success_count = 0
        kafka_error_count = 0
        sqs_success_count = 0
        sqs_error_count = 0
        
        if destination == 'kafka':
            kafka_result = send_records_to_kafka(
                processed_records, chunk_id, start_index, customer_id, tenant_id, batch_id,
                kafka_brokers, kafka_topic
            )
            kafka_success_count = kafka_result['success']
            kafka_error_count = kafka_result['errors']
        elif destination == 'sqs_core':
            sqs_result = send_records_to_sqs(
                processed_records, chunk_id, start_index, customer_id, tenant_id, batch_id,
                sqs_core_queue
            )
            sqs_success_count = sqs_result['success']
            sqs_error_count = sqs_result['errors']
        
        # Upload processed results to S3 (for backup/audit)
        result_key = f"results/{batch_id}/{chunk_id}.json"
        s3.put_object(
            Bucket=bucket,
            Key=result_key,
            Body=json.dumps(processed_records),
            ContentType='application/json'
        )
        
        # Upload processing errors if any
        error_key = None
        if processing_errors:
            error_key = f"errors/{batch_id}/{chunk_id}.json"
            s3.put_object(
                Bucket=bucket,
                Key=error_key,
                Body=json.dumps(processing_errors),
                ContentType='application/json'
            )
        
        processing_time = time.time() - start_time
        
        # Calculate success rates and performance metrics
        total_records_attempted = len(processed_records) + len(processing_errors)
        processing_success_rate = ((len(processed_records) - len(processing_errors)) / total_records_attempted * 100) if total_records_attempted > 0 else 0
        
        if destination == 'kafka':
            streaming_success_rate = ((kafka_success_count - kafka_error_count) / kafka_success_count * 100) if kafka_success_count > 0 else 0
        else:
            streaming_success_rate = ((sqs_success_count - sqs_error_count) / sqs_success_count * 100) if sqs_success_count > 0 else 0
        
        records_per_second = len(processed_records) / processing_time if processing_time > 0 else 0
        
        return {
            'chunkId': chunk_id,
            'batchId': batch_id,
            'customerId': customer_id,
            'tenantId': tenant_id,
            'deployment': 'WORKSPACE',
            'status': 'SUCCESS',
            'batchStatus': 'CHUNK_PROCESSED',
            'destination': destination,
            
            # Processing statistics
            'recordsProcessed': len(processed_records),
            'recordsAttempted': total_records_attempted,
            'processingErrors': len(processing_errors),
            'processingSuccessRate': processing_success_rate,
            'processingTime': processing_time,
            
            # Streaming statistics
            'recordsSentToKafka': kafka_success_count if destination == 'kafka' else 0,
            'kafkaErrors': kafka_error_count if destination == 'kafka' else 0,
            'recordsSentToSQSCore': sqs_success_count if destination == 'sqs_core' else 0,
            'sqsErrors': sqs_error_count if destination == 'sqs_core' else 0,
            'streamingSuccessRate': streaming_success_rate,
            
            # File locations
            'resultKey': result_key,
            'errorKey': error_key if processing_errors else None,
            'kafkaTopic': kafka_topic if destination == 'kafka' else None,
            'sqsCoreQueue': sqs_core_queue if destination == 'sqs_core' else None,
            
            # Progress tracking
            'progress': {
                'stage': 'CHUNK_PROCESSED',
                'chunkId': chunk_id,
                'startIndex': start_index,
                'endIndex': end_index,
                'recordsProcessed': len(processed_records),
                'processingErrors': len(processing_errors),
                'streamingErrors': kafka_error_count + sqs_error_count,
                'startTime': datetime.fromtimestamp(start_time).isoformat(),
                'completionTime': datetime.now().isoformat(),
                'processingTime': processing_time
            },
            
            # Performance metrics
            'performance': {
                'recordsPerSecond': records_per_second,
                'processingTime': processing_time,
                'successRate': processing_success_rate,
                'streamingSuccessRate': streaming_success_rate,
                'totalErrors': len(processing_errors) + kafka_error_count + sqs_error_count
            },
            
            # Metadata
            'metadata': {
                'source': 'lambda-processor',
                'version': '1.0',
                'chunkSize': end_index - start_index + 1,
                'destination': destination,
                'processedAt': datetime.now().isoformat()
            }
        }
        
    except Exception as e:
        logger.error(f"Error processing chunk {event.get('chunkId', 'unknown')}: {str(e)}")
        return {
            'chunkId': event.get('chunkId', 'unknown'),
            'batchId': event.get('batchId', 'unknown'),
            'customerId': event.get('customerId', 'unknown'),
            'tenantId': event.get('tenantId', 'unknown'),
            'deployment': 'WORKSPACE',
            'status': 'FAILED',
            'batchStatus': 'CHUNK_FAILED',
            'errorMessage': str(e),
            'errorTime': datetime.now().isoformat(),
            'processingTime': time.time() - start_time,
            'progress': {
                'stage': 'CHUNK_FAILED',
                'chunkId': event.get('chunkId', 'unknown'),
                'error': str(e),
                'startTime': datetime.fromtimestamp(start_time).isoformat(),
                'errorTime': datetime.now().isoformat()
            },
            'metadata': {
                'source': 'lambda-processor',
                'version': '1.0',
                'errorType': 'PROCESSING_ERROR',
                'processedAt': datetime.now().isoformat()
            }
        }

def lambda_handler(event, context):
    """Lambda handler for processing chunks (hybrid approach)"""
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Process the chunk
        result = process_chunk(event)
        
        logger.info(f"Chunk processing completed: {result['status']}")
        return result
        
    except Exception as e:
        logger.error(f"Lambda execution failed: {str(e)}")
        return create_error(f"Lambda execution failed: {str(e)}", 
                          event.get('batchId', 'unknown'),
                          event.get('customerId', 'unknown'),
                          event.get('tenantId', 'unknown'),
                          'WORKSPACE')

def create_error(error_message: str, batch_id: str = "unknown", 
                customer_id: str = "unknown", tenant_id: str = "unknown", 
                deployment: str = "unknown"):
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