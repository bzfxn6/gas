import json
import boto3
import logging
import time
from datetime import datetime
from typing import Dict, List, Any, Optional
from collections import defaultdict

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')

def validate_input(event):
    """Validate input parameters"""
    if not isinstance(event, list):
        return "Input must be a list of chunk results"
    return None

def aggregate_chunk_results(chunk_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Aggregate results from all processed chunks"""
    total_records = 0
    total_errors = 0
    total_processing_time = 0
    successful_chunks = 0
    failed_chunks = 0
    chunk_details = []
    
    # Process each chunk result
    for chunk_result in chunk_results:
        if chunk_result.get('status') == 'SUCCESS':
            successful_chunks += 1
            total_records += chunk_result.get('recordsProcessed', 0)
            total_errors += chunk_result.get('errors', 0)
            total_processing_time += chunk_result.get('processingTime', 0)
        else:
            failed_chunks += 1
        
        chunk_details.append({
            'chunkId': chunk_result.get('chunkId'),
            'status': chunk_result.get('status'),
            'recordsProcessed': chunk_result.get('recordsProcessed', 0),
            'errors': chunk_result.get('errors', 0),
            'processingTime': chunk_result.get('processingTime', 0),
            'error': chunk_result.get('error')
        })
    
    # Calculate success rate
    total_chunks = len(chunk_results)
    success_rate = (successful_chunks / total_chunks * 100) if total_chunks > 0 else 0
    
    # Calculate processing statistics
    avg_processing_time = total_processing_time / successful_chunks if successful_chunks > 0 else 0
    records_per_second = total_records / total_processing_time if total_processing_time > 0 else 0
        
        # Calculate destination statistics (exclusive routing)
    total_kafka_sent = sum(chunk.get('recordsSentToKafka', 0) for chunk in chunk_details)
    total_kafka_errors = sum(chunk.get('kafkaErrors', 0) for chunk in chunk_details)
    total_sqs_sent = sum(chunk.get('recordsSentToSQSCore', 0) for chunk in chunk_details)
    total_sqs_errors = sum(chunk.get('sqsErrors', 0) for chunk in chunk_details)
    
    # Determine which destination was used (should be exclusive)
    destinations_used = set(chunk.get('destination', 'unknown') for chunk in chunk_details)
    primary_destination = list(destinations_used)[0] if destinations_used else 'unknown'
    
        return {
        'totalChunks': total_chunks,
        'successfulChunks': successful_chunks,
        'failedChunks': failed_chunks,
        'successRate': success_rate,
        'totalRecordsProcessed': total_records,
        'totalErrors': total_errors,
        'totalProcessingTime': total_processing_time,
        'avgProcessingTimePerChunk': avg_processing_time,
        'recordsPerSecond': records_per_second,
        'primaryDestination': primary_destination,
        'kafkaStatistics': {
            'totalRecordsSent': total_kafka_sent,
            'totalErrors': total_kafka_errors,
            'successRate': ((total_kafka_sent - total_kafka_errors) / total_kafka_sent * 100) if total_kafka_sent > 0 else 0
        },
        'sqsStatistics': {
            'totalRecordsSent': total_sqs_sent,
            'totalErrors': total_sqs_errors,
            'successRate': ((total_sqs_sent - total_sqs_errors) / total_sqs_sent * 100) if total_sqs_sent > 0 else 0
        },
        'chunkDetails': chunk_details
    }

def collect_result_files(bucket: str, batch_id: str) -> List[Dict[str, Any]]:
    """Collect all result files from S3"""
    try:
        # List all result files for this batch
        prefix = f"results/{batch_id}/"
        paginator = s3_client.get_paginator('list_objects_v2')
        result_files = []
        
        for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
            if 'Contents' in page:
                for obj in page['Contents']:
                    if obj['Key'].endswith('.json'):
                        result_files.append({
                            'key': obj['Key'],
                            'size': obj['Size'],
                            'lastModified': obj['LastModified'].isoformat()
                        })
        
        logger.info(f"Found {len(result_files)} result files for batch {batch_id}")
        return result_files
        
    except Exception as e:
        logger.error(f"Error collecting result files: {str(e)}")
        raise

def download_and_merge_results(bucket: str, result_files: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Download and merge all result files"""
    all_records = []
    
    for file_info in result_files:
        try:
            response = s3_client.get_object(Bucket=bucket, Key=file_info['key'])
            records = json.loads(response['Body'].read().decode('utf-8'))
            
            if isinstance(records, list):
                all_records.extend(records)
            else:
                all_records.append(records)
                
            logger.info(f"Downloaded {len(records)} records from {file_info['key']}")
            
        except Exception as e:
            logger.error(f"Error downloading {file_info['key']}: {str(e)}")
            continue
    
    logger.info(f"Total records merged: {len(all_records)}")
    return all_records

def collect_error_reports(bucket: str, batch_id: str) -> List[Dict[str, Any]]:
    """Collect all error reports from S3"""
    try:
        prefix = f"errors/{batch_id}/"
        paginator = s3_client.get_paginator('list_objects_v2')
        error_files = []
        
        for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
            if 'Contents' in page:
                for obj in page['Contents']:
                    if obj['Key'].endswith('.json'):
                        error_files.append(obj['Key'])
        
        all_errors = []
        for error_file in error_files:
            try:
                response = s3_client.get_object(Bucket=bucket, Key=error_file)
                errors = json.loads(response['Body'].read().decode('utf-8'))
                
                if isinstance(errors, list):
                    all_errors.extend(errors)
                else:
                    all_errors.append(errors)
                    
            except Exception as e:
                logger.error(f"Error downloading error file {error_file}: {str(e)}")
                continue
        
        logger.info(f"Collected {len(all_errors)} error reports")
        return all_errors
        
    except Exception as e:
        logger.error(f"Error collecting error reports: {str(e)}")
        return []

def generate_processing_summary(aggregated_results: Dict[str, Any], 
                              all_records: List[Dict[str, Any]], 
                              all_errors: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Generate comprehensive processing summary"""
    
    # Analyze record patterns
    record_types = defaultdict(int)
    customer_ids = set()
    tenant_ids = set()
    
    for record in all_records:
        if isinstance(record, dict):
            record_types[record.get('type', 'unknown')] += 1
            if 'customerId' in record:
                customer_ids.add(record['customerId'])
            if 'tenantId' in record:
                tenant_ids.add(record['tenantId'])
    
    # Analyze error patterns
    error_types = defaultdict(int)
    for error in all_errors:
        if isinstance(error, dict):
            error_types[error.get('error', 'unknown')] += 1
    
    summary = {
        'processingSummary': {
            'totalRecordsProcessed': len(all_records),
            'totalErrors': len(all_errors),
            'successRate': ((len(all_records) - len(all_errors)) / len(all_records) * 100) if all_records else 0,
            'uniqueCustomers': len(customer_ids),
            'uniqueTenants': len(tenant_ids),
            'recordTypes': dict(record_types),
            'errorTypes': dict(error_types)
        },
        'performanceMetrics': {
            'totalProcessingTime': aggregated_results['totalProcessingTime'],
            'avgProcessingTimePerChunk': aggregated_results['avgProcessingTimePerChunk'],
            'recordsPerSecond': aggregated_results['recordsPerSecond'],
            'chunksPerSecond': aggregated_results['successfulChunks'] / aggregated_results['totalProcessingTime'] if aggregated_results['totalProcessingTime'] > 0 else 0
        },
        'chunkStatistics': {
            'totalChunks': aggregated_results['totalChunks'],
            'successfulChunks': aggregated_results['successfulChunks'],
            'failedChunks': aggregated_results['failedChunks'],
            'chunkSuccessRate': aggregated_results['successRate']
        }
    }
    
    return summary

def upload_final_results(bucket: str, batch_id: str, all_records: List[Dict[str, Any]], 
                        summary: Dict[str, Any]) -> str:
    """Upload final aggregated results to S3"""
    try:
        # Create final results structure
        final_results = {
            'batchId': batch_id,
            'processedAt': datetime.now().isoformat(),
            'summary': summary,
            'totalRecords': len(all_records),
            'records': all_records
        }
        
        # Upload to S3
        result_key = f"final-results/{batch_id}/aggregated-results.json"
        s3_client.put_object(
            Bucket=bucket,
            Key=result_key,
            Body=json.dumps(final_results, indent=2),
            ContentType='application/json'
        )
        
        logger.info(f"Uploaded final results to s3://{bucket}/{result_key}")
        return result_key
        
    except Exception as e:
        logger.error(f"Error uploading final results: {str(e)}")
        raise

def lambda_handler(event, context):
    """Main Lambda handler for aggregating results"""
    try:
        # Validate input
        error = validate_input(event)
        if error:
            return create_error(error)
        
        # Extract batch information from the first chunk result
        if not event or not isinstance(event, list) or len(event) == 0:
            return create_error("No chunk results provided")
        
        first_result = event[0]
        batch_id = first_result.get('batchId', 'unknown')
        customer_id = first_result.get('customerId', 'unknown')
        tenant_id = first_result.get('tenantId', 'unknown')
        deployment = first_result.get('deployment', 'WORKSPACE')
        bucket = first_result.get('bucket', 'unknown')
        
        logger.info(f"Starting result aggregation for batch {batch_id}")
        logger.info(f"Processing {len(event)} chunk results")
        
        # Aggregate chunk results
        aggregated_results = aggregate_chunk_results(event)
        
        # Collect result files from S3
        result_files = collect_result_files(bucket, batch_id)
        
        # Download and merge all results
        all_records = download_and_merge_results(bucket, result_files)
        
        # Collect error reports
        all_errors = collect_error_reports(bucket, batch_id)
        
        # Generate comprehensive summary
        summary = generate_processing_summary(aggregated_results, all_records, all_errors)
        
        # Upload final results
        final_result_key = upload_final_results(bucket, batch_id, all_records, summary)
        
        # Prepare response
        response = {
            'batchId': batch_id,
            'customerId': customer_id,
            'tenantId': tenant_id,
            'deployment': deployment,
            'bucket': bucket,
            'batchStatus': 'COMPLETED',
            'aggregatedResults': aggregated_results,
            'summary': summary,
            'finalResultKey': final_result_key,
            'totalRecordsProcessed': len(all_records),
            'totalErrors': len(all_errors),
            'processingTime': aggregated_results['totalProcessingTime'],
            'completionTime': datetime.now().isoformat()
        }
        
        logger.info(f"Result aggregation completed successfully for batch {batch_id}")
        logger.info(f"Processed {len(all_records):,} records with {len(all_errors)} errors")
        
        return response
        
    except Exception as e:
        logger.error(f"Error in result aggregation: {str(e)}")
        return create_error(f"Result aggregation failed: {str(e)}")

def create_error(error_message: str):
    """Create error response"""
    return {
        'batchStatus': 'SUBMISSION_FAILED',
        'errorMessage': error_message,
        'errorTime': datetime.now().isoformat()
    } 