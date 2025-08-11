#!/bin/bash

# User data script for AWS Batch instances
# This script configures the instance for optimal batch processing

set -e

# Update system packages
yum update -y

# Install additional packages for batch processing
yum install -y \
    python3 \
    python3-pip \
    jq \
    aws-cli \
    docker \
    git \
    htop \
    iotop \
    nethogs

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Configure Docker to use overlay2 storage driver for better performance
cat > /etc/docker/daemon.json << EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

# Restart Docker to apply configuration
systemctl restart docker

# Configure system limits for high-performance processing
cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF

# Configure sysctl for better performance
cat >> /etc/sysctl.conf << EOF
# Network performance
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000

# File system performance
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.swappiness = 1

# Process limits
kernel.pid_max = 65536
EOF

# Apply sysctl changes
sysctl -p

# Create batch processing user
useradd -m -s /bin/bash batchuser
usermod -aG docker batchuser

# Create batch processing directory
mkdir -p /opt/batch-processing
chown batchuser:batchuser /opt/batch-processing

# Install Python packages for batch processing
pip3 install --upgrade pip
pip3 install \
    boto3 \
    pandas \
    numpy \
    psutil \
    requests \
    tenacity \
    tqdm \
    kafka-python

# Configure AWS CLI for the batch user
mkdir -p /home/batchuser/.aws
cat > /home/batchuser/.aws/config << EOF
[default]
region = ${region}
output = json
EOF

chown -R batchuser:batchuser /home/batchuser/.aws

# Create batch processing script
cat > /opt/batch-processing/batch_processor.py << 'EOF'
#!/usr/bin/env python3
"""
AWS Batch Processor for large-scale data processing
Optimized for processing 60M+ records efficiently
"""

import os
import sys
import json
import time
import logging
import boto3
import argparse
import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional
from botocore.exceptions import ClientError
import psutil
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class BatchProcessor:
    def __init__(self, region: str, bucket: str):
        self.region = region
        self.bucket = bucket
        self.s3_client = boto3.client('s3', region_name=region)
        self.dynamodb = boto3.resource('dynamodb', region_name=region)
        
    def process_chunk(self, chunk_data: Dict[str, Any]) -> Dict[str, Any]:
        """Process a single chunk of data and send each record to Kafka"""
        start_time = time.time()
        
        try:
            chunk_id = chunk_data['chunkId']
            start_index = chunk_data['startIndex']
            end_index = chunk_data['endIndex']
            file_key = chunk_data['file']
            customer_id = chunk_data['customerId']
            tenant_id = chunk_data['tenantId']
            batch_id = chunk_data['batchId']
            
            # Configuration from environment
            kafka_brokers = os.environ.get('KAFKA_BROKERS', '').split(',')
            kafka_topic = os.environ.get('KAFKA_TOPIC', 'processed-records')
            sqs_core_queue = os.environ.get('SQS_CORE_QUEUE', '')
            destination = os.environ.get('RECORD_DESTINATION', 'kafka').lower()  # 'kafka' or 'sqs_core'
            
            logger.info(f"Processing chunk {chunk_id}: records {start_index:,} to {end_index:,}")
            logger.info(f"Destination: {destination}")
            logger.info(f"Kafka brokers: {kafka_brokers}, Topic: {kafka_topic}")
            logger.info(f"SQS Core Queue: {sqs_core_queue}")
            
            # Download chunk data from S3
            chunk_key = f"chunks/{batch_id}/{chunk_id}.json"
            response = self.s3_client.get_object(Bucket=self.bucket, Key=chunk_key)
            records = json.loads(response['Body'].read().decode('utf-8'))
            
            # Initialize Kafka producer if destination is Kafka
            producer = None
            if destination == 'kafka':
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
                        batch_size=16384,  # 16KB batch size
                        linger_ms=10,      # 10ms linger
                        compression_type='gzip'  # Compress messages
                    )
                    logger.info("Kafka producer initialized successfully")
                except Exception as e:
                    logger.error(f"Failed to initialize Kafka producer: {str(e)}")
                    if kafka_brokers and kafka_brokers[0]:  # Only raise if Kafka is configured
                        raise
            
            # Initialize SQS client if destination is SQS Core
            sqs_client = None
            if destination == 'sqs_core':
                try:
                    sqs_client = boto3.client('sqs', region_name=self.region)
                    logger.info("SQS client initialized successfully")
                except Exception as e:
                    logger.error(f"Failed to initialize SQS client: {str(e)}")
                    raise
            
            # Process all records first, then send to configured destination
            processed_records = []
            processing_errors = []
            
            # Process all records in the chunk
            for i, record in enumerate(records):
                try:
                    # Apply business logic transformations
                    processed_record = self.transform_record(record, customer_id, tenant_id)
                    processed_records.append(processed_record)
                    
                except Exception as e:
                    processing_errors.append({
                        'record_index': i,
                        'error': str(e),
                        'record': record
                    })
            
            # Now send all processed records to the configured destination
            kafka_success_count = 0
            kafka_error_count = 0
            sqs_success_count = 0
            sqs_error_count = 0
            
            logger.info(f"Sending {len(processed_records):,} processed records to {destination}")
            
            # Send all records to the configured destination
            if destination == 'kafka' and producer:
                for i, processed_record in enumerate(processed_records):
                    try:
                        # Add metadata to the record
                        kafka_message = {
                            'record': processed_record,
                            'metadata': {
                                'batchId': batch_id,
                                'chunkId': chunk_id,
                                'recordIndex': start_index + i,
                                'customerId': customer_id,
                                'tenantId': tenant_id,
                                'processedAt': datetime.now().isoformat(),
                                'source': 'batch-processor',
                                'destination': 'kafka'
                            }
                        }
                        
                        future = producer.send(kafka_topic, kafka_message)
                        # Don't wait for each message - use async sending for performance
                        kafka_success_count += 1
                        
                        # Progress logging every 10,000 records
                        if (i + 1) % 10000 == 0:
                            logger.info(f"Sent {i + 1:,} records to Kafka...")
                            
                    except Exception as kafka_error:
                        kafka_error_count += 1
                        logger.error(f"Kafka send error for record {i}: {str(kafka_error)}")
                        # Continue sending other records
                
            elif destination == 'sqs_core' and sqs_client:
                for i, processed_record in enumerate(processed_records):
                    try:
                        # Create SQS message
                        sqs_message = {
                            'record': processed_record,
                            'metadata': {
                                'batchId': batch_id,
                                'chunkId': chunk_id,
                                'recordIndex': start_index + i,
                                'customerId': customer_id,
                                'tenantId': tenant_id,
                                'processedAt': datetime.now().isoformat(),
                                'source': 'batch-processor',
                                'destination': 'sqs-core'
                            }
                        }
                        
                        response = sqs_client.send_message(
                            QueueUrl=sqs_core_queue,
                            MessageBody=json.dumps(sqs_message)
                        )
                        sqs_success_count += 1
                        
                        # Progress logging every 10,000 records
                        if (i + 1) % 10000 == 0:
                            logger.info(f"Sent {i + 1:,} records to SQS Core...")
                            
                    except Exception as sqs_error:
                        sqs_error_count += 1
                        logger.error(f"SQS send error for record {i}: {str(sqs_error)}")
                        # Continue sending other records
            
            # Flush Kafka producer to ensure all messages are sent
            if producer:
                try:
                    producer.flush(timeout=30)
                    logger.info(f"Kafka producer flushed successfully")
                except Exception as e:
                    logger.error(f"Error flushing Kafka producer: {str(e)}")
                finally:
                    producer.close()
            
            # Upload processed results to S3 (for backup/audit)
            result_key = f"results/{batch_id}/{chunk_id}.json"
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=result_key,
                Body=json.dumps(processed_records),
                ContentType='application/json'
            )
            
            # Upload processing errors if any
            if processing_errors:
                error_key = f"errors/{batch_id}/{chunk_id}.json"
                self.s3_client.put_object(
                    Bucket=self.bucket,
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
                'deployment': 'WORKSPACE',  # Could be made configurable
                'status': 'SUCCESS',
                'batchStatus': 'CHUNK_PROCESSED',
                'destination': destination,
                
                # Processing statistics
                'recordsProcessed': len(processed_records),
                'recordsAttempted': total_records_attempted,
                'processingErrors': len(processing_errors),
                'processingSuccessRate': processing_success_rate,
                'processingTime': processing_time,
                'recordsPerSecond': records_per_second,
                
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
                    'source': 'aws-batch-processor',
                    'version': '1.0',
                    'chunkSize': end_index - start_index + 1,
                    'destination': destination,
                    'processedAt': datetime.now().isoformat()
                }
            }
            
        except Exception as e:
            logger.error(f"Error processing chunk {chunk_data.get('chunkId', 'unknown')}: {str(e)}")
            return {
                'chunkId': chunk_data.get('chunkId', 'unknown'),
                'batchId': chunk_data.get('batchId', 'unknown'),
                'customerId': chunk_data.get('customerId', 'unknown'),
                'tenantId': chunk_data.get('tenantId', 'unknown'),
                'deployment': 'WORKSPACE',
                'status': 'FAILED',
                'batchStatus': 'CHUNK_FAILED',
                'errorMessage': str(e),
                'errorTime': datetime.now().isoformat(),
                'processingTime': time.time() - start_time,
                'progress': {
                    'stage': 'CHUNK_FAILED',
                    'chunkId': chunk_data.get('chunkId', 'unknown'),
                    'error': str(e),
                    'startTime': datetime.fromtimestamp(start_time).isoformat(),
                    'errorTime': datetime.now().isoformat()
                },
                'metadata': {
                    'source': 'aws-batch-processor',
                    'version': '1.0',
                    'errorType': 'PROCESSING_ERROR',
                    'processedAt': datetime.now().isoformat()
                }
            }
    
    def transform_record(self, record: Dict[str, Any], customer_id: str, tenant_id: str) -> Dict[str, Any]:
        """Apply business logic transformations to a record (replaces scm-batch-processor-update-records Lambda)"""
        # Add processing timestamp
        record['processedAt'] = datetime.now().isoformat()
        
        # Update customer and tenant IDs
        record['customerId'] = customer_id
        record['tenantId'] = tenant_id
        
        # Replace 'gssId' with a new UUID (from original Lambda)
        if 'gssId' in record:
            record['gssId'] = str(uuid.uuid4())
        
        # Generate new ID if needed
        if 'id' in record:
            record['originalId'] = record['id']
            record['id'] = f"{customer_id}_{tenant_id}_{int(time.time() * 1000)}"
        
        # Add any other business logic transformations here
        
        return record
    
    def monitor_resources(self):
        """Monitor system resources during processing"""
        while True:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            logger.info(f"System Resources - CPU: {cpu_percent}%, "
                       f"Memory: {memory.percent}%, "
                       f"Disk: {disk.percent}%")
            
            time.sleep(30)  # Monitor every 30 seconds

def main():
    parser = argparse.ArgumentParser(description='AWS Batch Processor')
    parser.add_argument('--chunk-id', required=True, help='Chunk ID to process')
    parser.add_argument('--start-index', type=int, required=True, help='Start index')
    parser.add_argument('--end-index', type=int, required=True, help='End index')
    parser.add_argument('--bucket', required=True, help='S3 bucket name')
    parser.add_argument('--file', required=True, help='S3 file key')
    parser.add_argument('--customer-id', required=True, help='Customer ID')
    parser.add_argument('--tenant-id', required=True, help='Tenant ID')
    parser.add_argument('--batch-id', required=True, help='Batch ID')
    
    args = parser.parse_args()
    
    # Get region from environment
    region = os.environ.get('AWS_REGION', 'eu-west-1')
    
    # Initialize processor
    processor = BatchProcessor(region, args.bucket)
    
    # Start resource monitoring in background
    monitor_thread = threading.Thread(target=processor.monitor_resources, daemon=True)
    monitor_thread.start()
    
    # Process chunk
    chunk_data = {
        'chunkId': args.chunk_id,
        'startIndex': args.start_index,
        'endIndex': args.end_index,
        'bucket': args.bucket,
        'file': args.file,
        'customerId': args.customer_id,
        'tenantId': args.tenant_id,
        'batchId': args.batch_id
    }
    
    result = processor.process_chunk(chunk_data)
    
    # Output result as JSON
    print(json.dumps(result))
    
    # Exit with appropriate code
    sys.exit(0 if result['status'] == 'SUCCESS' else 1)

if __name__ == '__main__':
    main()
EOF

chmod +x /opt/batch-processing/batch_processor.py

# Create batch validation script
cat > /opt/batch-processing/batch_validator.py << 'EOF'
#!/usr/bin/env python3
"""
AWS Batch Validator for large-scale data validation
Validates 60M+ records efficiently without timeout issues
"""

import os
import sys
import json
import time
import logging
import boto3
import argparse
from datetime import datetime
from typing import Dict, List, Any, Optional
from botocore.exceptions import ClientError
import psutil
import threading

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class BatchValidator:
    def __init__(self, region: str, bucket: str):
        self.region = region
        self.bucket = bucket
        self.s3_client = boto3.client('s3', region_name=region)
        
    def validate_record_format(self, record: dict, line_number: int):
        """Validate individual record format with enhanced checks for missing records"""
        try:
            # Check for completely empty or null records
            if not record or record is None:
                return False, "Record is empty or null", []
            
            # Check for required fields (enhanced list)
            required_fields = ['id', 'name', 'email', 'status', 'createdAt', 'updatedAt']
            missing_fields = []
            empty_fields = []
            
            for field in required_fields:
                if field not in record:
                    missing_fields.append(field)
                elif record[field] is None or record[field] == "" or record[field] == {} or record[field] == []:
                    empty_fields.append(field)
            
            # Check for missing required fields
            if missing_fields:
                return False, f"Missing required fields: {missing_fields}", missing_fields
            
            # Check for empty required fields
            if empty_fields:
                return False, f"Empty required fields: {empty_fields}", empty_fields
            
            # Enhanced email validation
            if 'email' in record:
                email = record['email']
                if not isinstance(email, str) or '@' not in email or '.' not in email:
                    return False, f"Invalid email format: {email}", ['email']
                
                # Check for common email issues
                if email.startswith('.') or email.endswith('.') or '..' in email:
                    return False, f"Invalid email format: {email}", ['email']
            
            # Enhanced status validation
            valid_statuses = ['active', 'inactive', 'pending', 'suspended', 'deleted']
            if 'status' in record and record['status'] not in valid_statuses:
                return False, f"Invalid status: {record['status']}", ['status']
            
            # Check for duplicate IDs (if we're tracking them)
            if 'id' in record:
                record_id = record['id']
                if not isinstance(record_id, (str, int)) or str(record_id).strip() == "":
                    return False, f"Invalid ID format: {record_id}", ['id']
            
            # Check for reasonable name length
            if 'name' in record:
                name = record['name']
                if not isinstance(name, str) or len(name.strip()) < 2 or len(name) > 255:
                    return False, f"Invalid name length: {name}", ['name']
            
            # Check for valid timestamps
            timestamp_fields = ['createdAt', 'updatedAt']
            for field in timestamp_fields:
                if field in record:
                    timestamp = record[field]
                    if not isinstance(timestamp, str):
                        return False, f"Invalid timestamp format for {field}: {timestamp}", [field]
                    
                    # Try to parse timestamp
                    try:
                        from datetime import datetime
                        datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                    except ValueError:
                        return False, f"Invalid timestamp format for {field}: {timestamp}", [field]
            
            return True, "", []
            
        except Exception as e:
            return False, f"Validation error: {str(e)}", []
    
    def validate_file_with_s3_select(self, bucket: str, file_key: str, batch_id: str):
        """Validate entire file using S3 Select with enhanced missing record detection"""
        try:
            start_time = time.time()
            records_processed = 0
            records_validated = 0
            records_failed = 0
            validation_errors = []
            
            # Track missing record patterns
            missing_record_patterns = {
                'empty_records': 0,
                'null_records': 0,
                'malformed_json': 0,
                'missing_required_fields': 0,
                'empty_required_fields': 0,
                'invalid_emails': 0,
                'invalid_statuses': 0,
                'invalid_timestamps': 0
            }
            
            logger.info(f"Starting ENHANCED validation for {file_key} - validating ALL records")
            
            # Use S3 Select to process entire file
            select_params = {
                'Bucket': bucket,
                'Key': file_key,
                'Expression': "SELECT * FROM S3Object",
                'ExpressionType': 'SQL',
                'InputSerialization': {
                    'JSON': {
                        'Type': 'LINES'
                    }
                },
                'OutputSerialization': {
                    'JSON': {
                        'RecordDelimiter': '\n'
                    }
                }
            }
            
            response = self.s3_client.select_object_content(**select_params)
            
            # Process each chunk as it comes in
            for event in response['Payload']:
                if 'Records' in event:
                    # Process records chunk
                    chunk_data = event['Records']['Payload'].decode('utf-8')
                    chunk_lines = chunk_data.splitlines()
                    
                    for line_number, line in enumerate(chunk_lines, start=records_processed + 1):
                        if line.strip():
                            try:
                                record = json.loads(line)
                                is_valid, error_message, field_errors = self.validate_record_format(record, line_number)
                                
                                if is_valid:
                                    records_validated += 1
                                else:
                                    records_failed += 1
                                    
                                    # Categorize the error
                                    if "empty or null" in error_message:
                                        missing_record_patterns['empty_records'] += 1
                                    elif "Missing required fields" in error_message:
                                        missing_record_patterns['missing_required_fields'] += 1
                                    elif "Empty required fields" in error_message:
                                        missing_record_patterns['empty_required_fields'] += 1
                                    elif "Invalid email" in error_message:
                                        missing_record_patterns['invalid_emails'] += 1
                                    elif "Invalid status" in error_message:
                                        missing_record_patterns['invalid_statuses'] += 1
                                    elif "Invalid timestamp" in error_message:
                                        missing_record_patterns['invalid_timestamps'] += 1
                                    
                                    validation_errors.append({
                                        'lineNumber': line_number,
                                        'error': error_message,
                                        'fieldErrors': field_errors,
                                        'record': record
                                    })
                                    
                                    # Progress logging every 100,000 records
                                    if records_processed % 100000 == 0:
                                        logger.info(f"Validated {records_processed:,} records... ({len(validation_errors)} errors so far)")
                                        
                            except json.JSONDecodeError as je:
                                records_failed += 1
                                missing_record_patterns['malformed_json'] += 1
                                validation_errors.append({
                                    'lineNumber': line_number,
                                    'error': f"Invalid JSON: {str(je)}",
                                    'fieldErrors': [],
                                    'record': line
                                })
                            
                            records_processed += 1
                    
                    # Continue processing all records (no early stopping)
                        
                elif 'End' in event:
                    break
                    
                elif 'Error' in event:
                    error_msg = event['Error']['Message']
                    logger.error(f"S3 Select error: {error_msg}")
                    raise Exception(f"S3 Select error: {error_msg}")
            
            # Calculate validation results
            validation_time = time.time() - start_time
            error_rate = (records_failed / records_processed * 100) if records_processed > 0 else 0
            
            # Enhanced validation criteria
            critical_error_threshold = 1.0  # 1% error rate is critical
            missing_fields_threshold = 0.5   # 0.5% missing fields is critical
            empty_fields_threshold = 0.5     # 0.5% empty fields is critical
            
            # Check for critical data quality issues
            missing_fields_rate = (missing_record_patterns['missing_required_fields'] / records_processed * 100) if records_processed > 0 else 0
            empty_fields_rate = (missing_record_patterns['empty_required_fields'] / records_processed * 100) if records_processed > 0 else 0
            
            validation_results = {
                'batchId': batch_id,
                'customerId': 'unknown',  # Could be passed as parameter
                'tenantId': 'unknown',    # Could be passed as parameter
                'deployment': 'WORKSPACE', # Could be passed as parameter
                'status': 'PENDING',      # Will be set below
                'batchStatus': 'VALIDATION_COMPLETED',
                'validationTime': validation_time,
                'recordsProcessed': records_processed,
                'recordsValidated': records_validated,
                'recordsFailed': records_failed,
                'errorRate': error_rate,
                'validationErrors': validation_errors[:1000],  # Keep first 1000 errors for detailed reporting
                'missingRecordPatterns': missing_record_patterns,
                'validationSummary': {
                    'totalErrors': len(validation_errors),
                    'totalRecords': records_processed,
                    'errorRate': error_rate,
                    'missingFieldsRate': missing_fields_rate,
                    'emptyFieldsRate': empty_fields_rate,
                    'validationType': 'ENHANCED_FULL_FILE_VALIDATION',
                    'criticalIssues': []
                },
                
                # Progress tracking
                'progress': {
                    'stage': 'VALIDATION_COMPLETED',
                    'totalRecords': records_processed,
                    'validRecords': records_validated,
                    'invalidRecords': records_failed,
                    'errorRate': error_rate,
                    'startTime': datetime.fromtimestamp(start_time).isoformat(),
                    'completionTime': datetime.now().isoformat(),
                    'validationTime': validation_time
                },
                
                # Performance metrics
                'performance': {
                    'recordsPerSecond': records_processed / validation_time if validation_time > 0 else 0,
                    'validationTime': validation_time,
                    'successRate': ((records_processed - records_failed) / records_processed * 100) if records_processed > 0 else 0,
                    'totalErrors': len(validation_errors)
                },
                
                # Metadata
                'metadata': {
                    'source': 'aws-batch-validator',
                    'version': '2.0',
                    'validationType': 'ENHANCED_FULL_FILE_VALIDATION',
                    'fileKey': file_key,
                    'bucket': bucket,
                    'processedAt': datetime.now().isoformat()
                }
            }
            
            # Enhanced validation decision logic
            critical_issues = []
            
            # Check for critical error rates
            if error_rate > critical_error_threshold:
                critical_issues.append(f"Critical error rate: {error_rate:.2f}% (threshold: {critical_error_threshold}%)")
            
            if missing_fields_rate > missing_fields_threshold:
                critical_issues.append(f"Critical missing fields rate: {missing_fields_rate:.2f}% (threshold: {missing_fields_threshold}%)")
            
            if empty_fields_rate > empty_fields_threshold:
                critical_issues.append(f"Critical empty fields rate: {empty_fields_rate:.2f}% (threshold: {empty_fields_threshold}%)")
            
            # Check for specific critical patterns
            if missing_record_patterns['malformed_json'] > 100:
                critical_issues.append(f"Too many malformed JSON records: {missing_record_patterns['malformed_json']}")
            
            if missing_record_patterns['empty_records'] > 1000:
                critical_issues.append(f"Too many empty records: {missing_record_patterns['empty_records']}")
            
            # Update validation summary with critical issues
            validation_results['validationSummary']['criticalIssues'] = critical_issues
            
            # Determine if validation passed
            if critical_issues:
                validation_results['status'] = 'FAILED'
                validation_results['errorMessage'] = f"ENHANCED validation failed - Critical data quality issues detected: {'; '.join(critical_issues)}"
                validation_results['batchStatus'] = 'VALIDATION_FAILED_CRITICAL'
            elif error_rate > 5 or len(validation_errors) > 1000:
                validation_results['status'] = 'FAILED'
                validation_results['errorMessage'] = f"ENHANCED validation failed - {error_rate:.2f}% error rate ({len(validation_errors):,} errors out of {records_processed:,} records)"
                validation_results['batchStatus'] = 'VALIDATION_FAILED'
            else:
                validation_results['status'] = 'PASSED'
                validation_results['errorMessage'] = None
                validation_results['batchStatus'] = 'VALIDATION_PASSED'
            
            logger.info(f"ENHANCED validation complete: {records_processed:,} records, {error_rate:.2f}% error rate, {len(validation_errors):,} errors")
            if critical_issues:
                logger.warning(f"CRITICAL ISSUES DETECTED: {'; '.join(critical_issues)}")
            
            return validation_results
            
        except Exception as e:
            logger.error(f"Error in enhanced validation: {str(e)}")
            raise
    
    def upload_validation_results(self, validation_results: Dict[str, Any], batch_id: str):
        """Upload validation results to S3"""
        try:
            validation_key = f"validation/{batch_id}/validation-results.json"
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=validation_key,
                Body=json.dumps(validation_results, indent=2),
                ContentType='application/json'
            )
            
            logger.info(f"Uploaded validation results to s3://{self.bucket}/{validation_key}")
            return validation_key
            
        except Exception as e:
            logger.error(f"Error uploading validation results: {str(e)}")
            raise

def main():
    parser = argparse.ArgumentParser(description='AWS Batch Validator')
    parser.add_argument('--bucket', required=True, help='S3 bucket name')
    parser.add_argument('--file', required=True, help='S3 file key')
    parser.add_argument('--customer-id', required=True, help='Customer ID')
    parser.add_argument('--tenant-id', required=True, help='Tenant ID')
    parser.add_argument('--batch-id', required=True, help='Batch ID')
    parser.add_argument('--deployment', required=True, help='Deployment')
    parser.add_argument('--snapshot-id', help='Snapshot ID')
    args = parser.parse_args()
    
    # Get region from environment
    region = os.environ.get('AWS_REGION', 'eu-west-1')
    
    # Initialize validator
    validator = BatchValidator(region, args.bucket)
    
    # Validate entire file
    validation_results = validator.validate_file_with_s3_select(
        bucket=args.bucket,
        file_key=args.file,
        batch_id=args.batch_id
    )
    
    # Upload results
    validator.upload_validation_results(validation_results, args.batch_id)
    
    # Output result as JSON
    print(json.dumps(validation_results))
    
    # Exit with appropriate code
    sys.exit(0 if validation_results['status'] == 'PASSED' else 1)

if __name__ == '__main__':
    main()
EOF

chmod +x /opt/batch-processing/batch_validator.py

# Create systemd service for batch processing
cat > /etc/systemd/system/batch-processor.service << EOF
[Unit]
Description=AWS Batch Processor
After=network.target

[Service]
Type=simple
User=batchuser
WorkingDirectory=/opt/batch-processing
ExecStart=/usr/bin/python3 /opt/batch-processing/batch_processor.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable batch-processor.service

# Create monitoring script
cat > /opt/batch-processing/monitor.sh << 'EOF'
#!/bin/bash

# Monitor script for batch processing instances
while true; do
    echo "=== System Status $(date) ==="
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "Memory Usage: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"
    echo "Docker Containers: $(docker ps -q | wc -l)"
    echo "================================"
    sleep 60
done
EOF

chmod +x /opt/batch-processing/monitor.sh

# Set up CloudWatch agent for monitoring
yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/batch-processor.log",
                        "log_group_name": "/aws/batch/processor",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "diskio": {
                "measurement": ["io_time"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent

# Create final status file
echo "Batch processing instance setup completed at $(date)" > /opt/batch-processing/setup-complete.txt

# Signal completion
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${region} 