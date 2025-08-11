import json
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Test Lambda function to demonstrate hash generation approach.
    
    Args:
        event: Lambda event
        context: Lambda context
        
    Returns:
        dict: Response with event details and function info
    """
    logger.info("Test Lambda function executed")
    
    # Log the event for debugging
    logger.info(f"Event: {json.dumps(event)}")
    
    # Return a simple response
    response = {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello from test Lambda function!",
            "event": event,
            "function_name": context.function_name,
            "function_version": context.function_version,
            "memory_limit": context.memory_limit_in_mb,
            "remaining_time": context.get_remaining_time_in_millis()
        })
    }
    
    logger.info(f"Response: {json.dumps(response)}")
    return response # NEW COMMENT ADDED FOR TESTING
