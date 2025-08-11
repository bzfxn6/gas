import json
import boto3
import logging
import math
import uuid
from datetime import datetime
from typing import Dict, List, Any

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

def get_file_size_and_estimate_records(bucket: str, file_key: str) -> tuple:
    """Get file size and estimate number of records"""
    try:
        head = s3_client.head_object(Bucket=bucket, Key=file_key)
        file_size = head['ContentLength']
        
        # Estimate records based on file size (rough estimate: 1KB per record)
        estimated_records = max(1000000, file_size // 1024)  # Minimum 1M records
        
        logger.info(f"File size: {file_size:,} bytes, estimated records: {estimated_records:,}")
        return file_size, estimated_records
        
    except Exception as e:
        logger.error(f"Error getting file size: {str(e)}")
        raise

def calculate_optimal_chunk_size(total_records: int, max_concurrent: int, max_chunk_size: int) -> int:
    """Calculate optimal chunk size based on total records and concurrency"""
    # Start with max concurrent chunks
    optimal_chunks = max_concurrent
    
    # Calculate chunk size
    chunk_size = math.ceil(total_records / optimal_chunks)
    
    # Ensure chunk size doesn't exceed maximum
    chunk_size = min(chunk_size, max_chunk_size)
    
    # Recalculate number of chunks with the final chunk size
    final_chunks = math.ceil(total_records / chunk_size)
    
    logger.info(f"Optimal chunk size: {chunk_size:,}, total chunks: {final_chunks}")
    
    return chunk_size, final_chunks

def create_chunks(total_records: int, chunk_size: int, batch_id: str, 
                 bucket: str, file_key: str, customer_id: str, tenant_id: str, destination: str) -> List[Dict[str, Any]]:
    """Create chunk definitions for processing"""
    chunks = []
    
    for i in range(0, total_records, chunk_size):
        chunk_id = f"chunk_{i//chunk_size:06d}"
        start_index = i
        end_index = min(i + chunk_size - 1, total_records - 1)
        
        chunk = {
            'chunkId': chunk_id,
            'startIndex': start_index,
            'endIndex': end_index,
            'chunkSize': end_index - start_index + 1,
            'bucket': bucket,
            'file': file_key,
            'customerId': customer_id,
            'tenantId': tenant_id,
            'batchId': batch_id,
            'destination': destination,
            'chunkNumber': len(chunks) + 1,
            'estimatedProcessingTime': (end_index - start_index + 1) * 0.005,  # 5ms per record
            'createdAt': datetime.now().isoformat()
        }
        
        chunks.append(chunk)
    
    logger.info(f"Created {len(chunks)} chunks for {total_records:,} records")
    return chunks

def upload_chunk_metadata(chunks: List[Dict[str, Any]], batch_id: str, bucket: str):
    """Upload chunk metadata to S3"""
    try:
        metadata = {
            'batchId': batch_id,
            'totalChunks': len(chunks),
            'totalRecords': sum(chunk['chunkSize'] for chunk in chunks),
            'chunks': chunks,
            'createdAt': datetime.now().isoformat(),
            'metadataVersion': '1.0'
        }
        
        metadata_key = f"metadata/{batch_id}/chunks.json"
        s3_client.put_object(
            Bucket=bucket,
            Key=metadata_key,
            Body=json.dumps(metadata, indent=2),
            ContentType='application/json'
        )
        
        logger.info(f"Uploaded chunk metadata to s3://{bucket}/{metadata_key}")
        return metadata_key
        
    except Exception as e:
        logger.error(f"Error uploading chunk metadata: {str(e)}")
        raise

def calculate_processing_estimates(chunks: List[Dict[str, Any]], max_concurrent: int) -> Dict[str, Any]:
    """Calculate processing time and resource estimates"""
    total_records = sum(chunk['chunkSize'] for chunk in chunks)
    total_chunks = len(chunks)
    
    # Calculate processing time estimates
    total_processing_time = sum(chunk['estimatedProcessingTime'] for chunk in chunks)
    parallel_processing_time = total_processing_time / max_concurrent
    
    # Add buffer for overhead (20%)
    estimated_total_time = parallel_processing_time * 1.2
    
    # Calculate resource requirements
    avg_chunk_size = total_records / total_chunks
    memory_per_chunk = avg_chunk_size * 0.5  # 0.5KB per record
    total_memory = memory_per_chunk * max_concurrent
    
    estimates = {
        'totalRecords': total_records,
        'totalChunks': total_chunks,
        'maxConcurrentChunks': max_concurrent,
        'estimatedTotalTime': estimated_total_time,
        'estimatedParallelTime': parallel_processing_time,
        'avgChunkSize': avg_chunk_size,
        'memoryPerChunk': memory_per_chunk,
        'totalMemoryRequired': total_memory,
        'processingRate': total_records / estimated_total_time if estimated_total_time > 0 else 0,
        'chunksPerHour': (3600 / estimated_total_time) * total_chunks if estimated_total_time > 0 else 0
    }
    
    logger.info(f"Processing estimates: {json.dumps(estimates, indent=2)}")
    return estimates

def lambda_handler(event, context):
    """Main Lambda handler for calculating chunks"""
    try:
        # Validate input
        error = validate_input(event)
        if error:
            return create_error(error, event.get('batchId', 'unknown'))
        
        # Extract parameters
        bucket = event['bucket']
        file_key = event['file']
        customer_id = event['customerId']
        tenant_id = event['tenantId']
        batch_id = event['batchId']
        deployment = event.get('deployment', 'WORKSPACE')
        snapshot_id = event.get('snapshotId')
        
        # Get configuration from environment or use defaults
        max_concurrent_chunks = int(event.get('maxConcurrentChunks', 50))
        max_chunk_size = int(event.get('maxChunkSize', 500000))
        target_total_records = int(event.get('targetTotalRecords', 60000000))
        
        logger.info(f"Starting chunk calculation for batch {batch_id}")
        logger.info(f"Configuration: max_concurrent={max_concurrent_chunks}, max_chunk_size={max_chunk_size:,}")
        
        # Get file size and estimate records
        file_size, estimated_records = get_file_size_and_estimate_records(bucket, file_key)
        
        # Use target total records if provided, otherwise use estimated
        total_records = target_total_records if target_total_records > 0 else estimated_records
        
        # Calculate optimal chunk size
        chunk_size, total_chunks = calculate_optimal_chunk_size(
            total_records, max_concurrent_chunks, max_chunk_size
        )
        
        # Get destination from environment or use default
        destination = event.get('destination', 'kafka')
        
        # Create chunks
        chunks = create_chunks(
            total_records, chunk_size, batch_id, 
            bucket, file_key, customer_id, tenant_id, destination
        )
        
        # Upload chunk metadata
        metadata_key = upload_chunk_metadata(chunks, batch_id, bucket)
        
        # Calculate processing estimates
        estimates = calculate_processing_estimates(chunks, max_concurrent_chunks)
        
        # Prepare response
        response = {
            'batchId': batch_id,
            'customerId': customer_id,
            'tenantId': tenant_id,
            'snapshotId': snapshot_id,
            'deployment': deployment,
            'bucket': bucket,
            'file': file_key,
            'batchStatus': 'CHUNKS_CALCULATED',
            'chunks': chunks,
            'metadataKey': metadata_key,
            'estimates': estimates,
            'configuration': {
                'maxConcurrentChunks': max_concurrent_chunks,
                'maxChunkSize': max_chunk_size,
                'chunkSize': chunk_size,
                'totalChunks': total_chunks,
                'totalRecords': total_records
            },
            'progress': {
                'stage': 'CHUNKS_CALCULATED',
                'totalChunks': total_chunks,
                'chunksProcessed': 0,
                'chunksInProgress': 0,
                'chunksFailed': 0,
                'recordsProcessed': 0,
                'startTime': datetime.now().isoformat(),
                'lastUpdateTime': datetime.now().isoformat()
            }
        }
        
        logger.info(f"Chunk calculation completed successfully for batch {batch_id}")
        logger.info(f"Created {total_chunks} chunks for {total_records:,} records")
        
        return response
        
    except Exception as e:
        logger.error(f"Error in chunk calculation: {str(e)}")
        return create_error(f"Chunk calculation failed: {str(e)}", 
                          event.get('batchId', 'unknown'),
                          event.get('customerId', 'unknown'),
                          event.get('tenantId', 'unknown'),
                          event.get('deployment', 'unknown'))

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