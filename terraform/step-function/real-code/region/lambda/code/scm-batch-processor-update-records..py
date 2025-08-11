import json
import boto3
import uuid
import logging
 
# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
 
s3_client = boto3.client('s3')
 
def validate_input(event):
    required_fields = ['bucket', 'file', 'customerId', 'tenantId', 'batchId']
    missing_fields = [field for field in required_fields if not event.get(field)]
    if missing_fields:
        return create_error(f"Missing required fields: {', '.join(missing_fields)}")
 
def lambda_handler(event):
    try:
        # Initialize counters
        processed_count = 0
        error_count = 0

        # Validate input parameters
        validate_input(event)

        bucket = event['bucket']            # Retrieved from Step Function input
        file = event['file']                # Retrieved from Step Function input
        customer_id = event['customerId']   # Retrieved from Step Function input
        tenant_id = event['tenantId']       # Retrieved from Step Function input
        batch_id = event['batchId']         # Retrieved from Step Function input
        snapshot_id = event['snapshotId']   # Retrieved from Step Function input
        deployment = event['deployment']    # Retrieved from Step Function input

        logger.info(f"Processing file {file} from bucket {bucket}")
        logger.info(f"BatchId: {batch_id}, CustomerId: {customer_id}, TenantId: {tenant_id}, Deployment: {deployment}, SnapshotId: {snapshot_id}")

        try:
            response = s3_client.get_object(Bucket=bucket, Key=file)
            content = response['Body'].read().decode('utf-8')
        except s3_client.exceptions.NoSuchKey:
            return create_error(f"File {file} not found in bucket {bucket}")
        except s3_client.exceptions.NoSuchBucket:
            return create_error(f"Bucket {bucket} does not exist")
        except Exception as e:
            return create_error(f"Error reading file from S3: {str(e)}")

        # Split content into lines and process each line
        lines = content.splitlines()
        if not lines:
            return create_error("File is empty")

        results = []
        error_messages = []  # List to gather any processing errors if needed

        #for line in lines:
        for line_number, line in enumerate(lines, 1):
            try:
                if not line.strip():
                    continue  # Skip empty lines

                record = json.loads(line)  # Assuming each line is a JSON object

                if not isinstance(record, dict):
                    return create_error(f"Invalid record format at line {line_number}")

                if record.get('customerId') == customer_id:
                    # Replace 'gssId' with a new UUID
                    if 'gssId' in record:
                        record['gssId'] = str(uuid.uuid4())  # Generate a new UUID

                    # Replace 'tenantId' in record with 'tenantId' from Step Function input
                    if 'tenantId' in record:
                        record['tenantId'] = tenant_id

                    # Add 'snapshotId' as 'clientReference' to the record for workspace deployment
                    if deployment == 'WORKSPACE':
                        record['clientReference'] = snapshot_id

                    # Remove the specified fields
                    record.pop('eventDateTime', None)
                    record.pop('timestamps', None)
                    record.pop('metadata', None)

                    results.append(record)
                    processed_count += 1

            except json.JSONDecodeError as je:
                error_msg = f"Invalid JSON at line {line_number}: {str(je)}"
                error_messages.append(error_msg)
                error_count += 1
            except Exception as line_error:
                error_msg = f"Error processing line {line_number}: {str(line_error)}"
                error_messages.append(error_msg)
                error_count += 1

        logger.info(f"Processed {processed_count} records, encountered {error_count} errors")

        if not results:
            return create_error("No valid records found for processing")

        # Log the processed records
        print("Processed Records:", results)

        # Output results to S3, large batches are too big to pass variables between Lambdas via the step function.
        random_name = uuid.uuid4().hex
        filename = f'tmp/{random_name}/result.json'

        try:
            s3_client.put_object(
                Bucket=bucket,
                Body=json.dumps(results),
                Key=filename
            )
        except Exception as s3_error:
            raise IOError(f"Error writing results to S3: {str(s3_error)}")

        # Determine final status - fail if any errors occurred
        status = 'SUCCESS' if error_count == 0 else 'FAILED'

        # Return the results along with a status
        response_body = {
            'status': status,
            'processedCount': processed_count,
            'errorCount': error_count,
            'errors': error_messages[:10] if error_messages else [],  # Limit number of errors returne
            'batchId': batch_id,
            'customerId': customer_id,
            'tenantId': tenant_id,
            'snapshotId': snapshot_id,
            'deployment': deployment,
            'Bucket': bucket,
            'Key': filename
        }

        logger.info(f"Completed processing with status: {status}")
        return response_body

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return create_error(f"Unexpected error: {str(e)}", batch_id) 