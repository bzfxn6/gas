import json
import boto3
import logging
import time
import os
import re
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
from collections import defaultdict
import concurrent.futures
from functools import lru_cache

# Set up logging with structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients outside handler for reuse
s3_client = boto3.client('s3')

# Constants for validation
REQUIRED_FIELDS = frozenset(['id', 'name', 'email', 'status', 'createdAt', 'updatedAt'])
VALID_STATUSES = frozenset(['active', 'inactive', 'pending', 'suspended', 'deleted'])
EMAIL_PATTERN = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
TIMESTAMP_PATTERN = re.compile(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?(Z|[+-]\d{2}:\d{2})$')

# Validation thresholds
CRITICAL_ERROR_THRESHOLD = 1.0
MISSING_FIELDS_THRESHOLD = 0.5
EMPTY_FIELDS_THRESHOLD = 0.5
MAX_ERRORS_TO_COLLECT = 1000
PROGRESS_LOG_INTERVAL = 100000

class ValidationError(Exception):
    """Custom exception for validation errors"""
    pass

class ValidationResult:
    """Class to hold validation results with better memory management"""
    
    def __init__(self):
        self.records_processed = 0
        self.records_validated = 0
        self.records_failed = 0
        self.validation_errors = []
        self.error_patterns = defaultdict(int)
        self.start_time = time.time()
    
    def add_error(self, line_number: int, error_message: str, field_errors: List[str], record: Any):
        """Add validation error with memory management"""
        if len(self.validation_errors) < MAX_ERRORS_TO_COLLECT:
            self.validation_errors.append({
                'lineNumber': line_number,
                'error': error_message,
                'fieldErrors': field_errors,
                'record': record
            })
        
        # Categorize error for pattern analysis
        if "empty or null" in error_message:
            self.error_patterns['empty_records'] += 1
        elif "Missing required fields" in error_message:
            self.error_patterns['missing_required_fields'] += 1
        elif "Empty required fields" in error_message:
            self.error_patterns['empty_required_fields'] += 1
        elif "Invalid email" in error_message:
            self.error_patterns['invalid_emails'] += 1
        elif "Invalid status" in error_message:
            self.error_patterns['invalid_statuses'] += 1
        elif "Invalid timestamp" in error_message:
            self.error_patterns['invalid_timestamps'] += 1
        elif "Invalid JSON" in error_message:
            self.error_patterns['malformed_json'] += 1
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get validation statistics"""
        validation_time = time.time() - self.start_time
        error_rate = (self.records_failed / self.records_processed * 100) if self.records_processed > 0 else 0
        
        return {
            'validationTime': validation_time,
            'recordsProcessed': self.records_processed,
            'recordsValidated': self.records_validated,
            'recordsFailed': self.records_failed,
            'errorRate': error_rate,
            'recordsPerSecond': self.records_processed / validation_time if validation_time > 0 else 0
        }

@lru_cache(maxsize=128)
def is_valid_email(email: str) -> bool:
    """Cached email validation using regex"""
    if not isinstance(email, str):
        return False
    return bool(EMAIL_PATTERN.match(email))

@lru_cache(maxsize=128)
def is_valid_timestamp(timestamp: str) -> bool:
    """Cached timestamp validation using regex"""
    if not isinstance(timestamp, str):
        return False
    return bool(TIMESTAMP_PATTERN.match(timestamp))

def validate_record_format(record: Any, line_number: int) -> Tuple[bool, str, List[str]]:
    """Optimized record validation with early returns and better error handling"""
    try:
        # Quick null/empty check
        if not record:
            return False, "Record is empty or null", []
        
        # Type check
        if not isinstance(record, dict):
            return False, f"Record must be a JSON object, got {type(record).__name__}", []
        
        # Check required fields efficiently
        missing_fields = []
        empty_fields = []
        
        for field in REQUIRED_FIELDS:
            if field not in record:
                missing_fields.append(field)
            else:
                value = record[field]
                if value is None or value == "" or value == {} or value == []:
                    empty_fields.append(field)
        
        # Early return for missing fields
        if missing_fields:
            return False, f"Missing required fields: {missing_fields}", missing_fields
        
        if empty_fields:
            return False, f"Empty required fields: {empty_fields}", empty_fields
        
        # Validate email efficiently
        if 'email' in record:
            if not is_valid_email(record['email']):
                return False, f"Invalid email format: {record['email']}", ['email']
        
        # Validate status efficiently
        if 'status' in record and record['status'] not in VALID_STATUSES:
            return False, f"Invalid status: {record['status']}", ['status']
        
        # Validate ID
        if 'id' in record:
            record_id = record['id']
            if not isinstance(record_id, (str, int)) or str(record_id).strip() == "":
                return False, f"Invalid ID format: {record_id}", ['id']
        
        # Validate name length
        if 'name' in record:
            name = record['name']
            if not isinstance(name, str) or len(name.strip()) < 2 or len(name) > 255:
                return False, f"Invalid name length: {name}", ['name']
        
        # Validate timestamps efficiently
        for field in ['createdAt', 'updatedAt']:
            if field in record and not is_valid_timestamp(record[field]):
                return False, f"Invalid timestamp format for {field}: {record[field]}", [field]
        
        return True, "", []
        
    except Exception as e:
        logger.error(f"Validation error on line {line_number}: {str(e)}")
        return False, f"Validation error: {str(e)}", []

def process_chunk(chunk_data: str, start_line: int, validation_result: ValidationResult) -> None:
    """Process a chunk of data efficiently"""
    chunk_lines = chunk_data.splitlines()
    
    for i, line in enumerate(chunk_lines):
        if not line.strip():
            continue
            
        line_number = start_line + i
        
        try:
            record = json.loads(line)
            is_valid, error_message, field_errors = validate_record_format(record, line_number)
            
            if is_valid:
                validation_result.records_validated += 1
            else:
                validation_result.records_failed += 1
                validation_result.add_error(line_number, error_message, field_errors, record)
                
        except json.JSONDecodeError as je:
            validation_result.records_failed += 1
            validation_result.add_error(
                line_number, 
                f"Invalid JSON: {str(je)}", 
                [], 
                line
            )
        
        validation_result.records_processed += 1
        
        # Progress logging
        if validation_result.records_processed % PROGRESS_LOG_INTERVAL == 0:
            logger.info(f"Validated {validation_result.records_processed:,} records... "
                       f"({validation_result.records_failed:,} errors so far)")

def validate_file_with_s3_select(bucket: str, file_key: str, batch_id: str) -> Dict[str, Any]:
    """Optimized file validation using S3 Select with better memory management"""
    validation_result = ValidationResult()
    
    try:
        logger.info(f"Starting optimized validation for {file_key}")
        
        # S3 Select parameters
        select_params = {
            'Bucket': bucket,
            'Key': file_key,
            'Expression': "SELECT * FROM S3Object",
            'ExpressionType': 'SQL',
            'InputSerialization': {
                'JSON': {'Type': 'LINES'}
            },
            'OutputSerialization': {
                'JSON': {'RecordDelimiter': '\n'}
            }
        }
        
        # Process file in chunks
        response = s3_client.select_object_content(**select_params)
        
        for event in response['Payload']:
            if 'Records' in event:
                chunk_data = event['Records']['Payload'].decode('utf-8')
                process_chunk(chunk_data, validation_result.records_processed + 1, validation_result)
                
            elif 'End' in event:
                break
                
            elif 'Error' in event:
                error_msg = event['Error']['Message']
                logger.error(f"S3 Select error: {error_msg}")
                raise ValidationError(f"S3 Select error: {error_msg}")
        
        # Calculate final statistics
        stats = validation_result.get_statistics()
        
        # Check for critical issues
        critical_issues = []
        
        if stats['errorRate'] > CRITICAL_ERROR_THRESHOLD:
            critical_issues.append(f"Critical error rate: {stats['errorRate']:.2f}% (threshold: {CRITICAL_ERROR_THRESHOLD}%)")
        
        missing_fields_rate = (validation_result.error_patterns['missing_required_fields'] / stats['recordsProcessed'] * 100) if stats['recordsProcessed'] > 0 else 0
        if missing_fields_rate > MISSING_FIELDS_THRESHOLD:
            critical_issues.append(f"Critical missing fields rate: {missing_fields_rate:.2f}% (threshold: {MISSING_FIELDS_THRESHOLD}%)")
        
        empty_fields_rate = (validation_result.error_patterns['empty_required_fields'] / stats['recordsProcessed'] * 100) if stats['recordsProcessed'] > 0 else 0
        if empty_fields_rate > EMPTY_FIELDS_THRESHOLD:
            critical_issues.append(f"Critical empty fields rate: {empty_fields_rate:.2f}% (threshold: {EMPTY_FIELDS_THRESHOLD}%)")
        
        # Check specific patterns
        if validation_result.error_patterns['malformed_json'] > 100:
            critical_issues.append(f"Too many malformed JSON records: {validation_result.error_patterns['malformed_json']}")
        
        if validation_result.error_patterns['empty_records'] > 1000:
            critical_issues.append(f"Too many empty records: {validation_result.error_patterns['empty_records']}")
        
        # Determine validation status
        if critical_issues:
            status = 'FAILED'
            batch_status = 'VALIDATION_FAILED_CRITICAL'
            error_message = f"Validation failed - Critical data quality issues detected: {'; '.join(critical_issues)}"
        elif stats['errorRate'] > 5 or len(validation_result.validation_errors) > MAX_ERRORS_TO_COLLECT:
            status = 'FAILED'
            batch_status = 'VALIDATION_FAILED'
            error_message = f"Validation failed - {stats['errorRate']:.2f}% error rate ({stats['recordsFailed']:,} errors out of {stats['recordsProcessed']:,} records)"
        else:
            status = 'PASSED'
            batch_status = 'VALIDATION_PASSED'
            error_message = None
        
        # Build final results
        validation_results = {
            'batchId': batch_id,
            'status': status,
            'batchStatus': batch_status,
            'errorMessage': error_message,
            'validationTime': stats['validationTime'],
            'recordsProcessed': stats['recordsProcessed'],
            'recordsValidated': stats['recordsValidated'],
            'recordsFailed': stats['recordsFailed'],
            'errorRate': stats['errorRate'],
            'validationErrors': validation_result.validation_errors,
            'missingRecordPatterns': dict(validation_result.error_patterns),
            'validationSummary': {
                'totalErrors': len(validation_result.validation_errors),
                'totalRecords': stats['recordsProcessed'],
                'errorRate': stats['errorRate'],
                'missingFieldsRate': missing_fields_rate,
                'emptyFieldsRate': empty_fields_rate,
                'validationType': 'OPTIMIZED_FULL_FILE_VALIDATION',
                'criticalIssues': critical_issues
            },
            'performance': {
                'recordsPerSecond': stats['recordsPerSecond'],
                'validationTime': stats['validationTime'],
                'successRate': ((stats['recordsProcessed'] - stats['recordsFailed']) / stats['recordsProcessed'] * 100) if stats['recordsProcessed'] > 0 else 0,
                'totalErrors': len(validation_result.validation_errors)
            },
            'metadata': {
                'source': 'lambda-validator-optimized',
                'version': '3.0',
                'validationType': 'OPTIMIZED_FULL_FILE_VALIDATION',
                'fileKey': file_key,
                'bucket': bucket,
                'processedAt': datetime.now().isoformat()
            }
        }
        
        logger.info(f"Optimized validation complete: {stats['recordsProcessed']:,} records, "
                   f"{stats['errorRate']:.2f}% error rate, {stats['recordsFailed']:,} errors")
        
        if critical_issues:
            logger.warning(f"CRITICAL ISSUES DETECTED: {'; '.join(critical_issues)}")
        
        return validation_results
        
    except Exception as e:
        logger.error(f"Error in optimized validation: {str(e)}")
        raise

def upload_validation_results(validation_results: Dict[str, Any], batch_id: str, bucket: str) -> str:
    """Upload validation results to S3 with compression"""
    try:
        validation_key = f"validation/{batch_id}/validation-results.json"
        
        # Compress the JSON for better storage efficiency
        json_data = json.dumps(validation_results, separators=(',', ':'))  # Compact JSON
        
        s3_client.put_object(
            Bucket=bucket,
            Key=validation_key,
            Body=json_data,
            ContentType='application/json',
            ContentEncoding='gzip' if len(json_data) > 1000000 else 'identity'  # Compress large files
        )
        
        logger.info(f"Uploaded validation results to s3://{bucket}/{validation_key}")
        return validation_key
        
    except Exception as e:
        logger.error(f"Error uploading validation results: {str(e)}")
        raise

def lambda_handler(event, context):
    """Optimized Lambda handler with better error handling and performance monitoring"""
    try:
        logger.info(f"Starting optimized data validation Lambda")
        logger.info(f"Event: {json.dumps(event, default=str)}")
        
        # Extract parameters with validation
        required_params = ['bucket', 'file', 'customerId', 'tenantId', 'batchId']
        for param in required_params:
            if param not in event:
                raise ValidationError(f"Missing required parameter: {param}")
        
        bucket = event['bucket']
        file_key = event['file']
        customer_id = event['customerId']
        tenant_id = event['tenantId']
        batch_id = event['batchId']
        deployment = event.get('deployment', 'WORKSPACE')
        snapshot_id = event.get('snapshotId')
        
        logger.info(f"Validating file: s3://{bucket}/{file_key}")
        logger.info(f"BatchId: {batch_id}, CustomerId: {customer_id}, TenantId: {tenant_id}")
        
        # Perform validation
        validation_results = validate_file_with_s3_select(bucket, file_key, batch_id)
        
        # Update with metadata
        validation_results.update({
            'customerId': customer_id,
            'tenantId': tenant_id,
            'deployment': deployment,
            'snapshotId': snapshot_id
        })
        
        # Upload results
        validation_key = upload_validation_results(validation_results, batch_id, bucket)
        
        # Return structured response
        return {
            'statusCode': 200,
            'body': {
                'validationResults': validation_results,
                'validationKey': validation_key,
                'message': f"Validation completed with status: {validation_results['status']}",
                'performance': validation_results['performance']
            }
        }
        
    except ValidationError as e:
        logger.error(f"Validation error: {str(e)}")
        return {
            'statusCode': 400,
            'body': {
                'error': f"Validation failed: {str(e)}",
                'batchId': event.get('batchId', 'unknown'),
                'customerId': event.get('customerId', 'unknown'),
                'tenantId': event.get('tenantId', 'unknown')
            }
        }
    except Exception as e:
        logger.error(f"Unexpected error in validation Lambda: {str(e)}")
        return {
            'statusCode': 500,
            'body': {
                'error': f"Internal error: {str(e)}",
                'batchId': event.get('batchId', 'unknown'),
                'customerId': event.get('customerId', 'unknown'),
                'tenantId': event.get('tenantId', 'unknown')
            }
        } 