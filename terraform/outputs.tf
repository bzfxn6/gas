output "queue_urls" {
  description = "URLs of the created SQS queues"
  value = {
    for k, v in aws_sqs_queue.sqs_queue : k => v.url
  }
}

output "queue_arns" {
  description = "ARNs of the created SQS queues"
  value = {
    for k, v in aws_sqs_queue.sqs_queue : k => v.arn
  }
}

output "dlq_urls" {
  description = "URLs of the created DLQ queues"
  value = {
    for k, v in aws_sqs_queue.deadletter_queue : k => v.url
  }
}

output "dlq_arns" {
  description = "ARNs of the created DLQ queues"
  value = {
    for k, v in aws_sqs_queue.deadletter_queue : k => v.arn
  }
}

output "ssm_parameters" {
  description = "Created SSM parameters"
  value = {
    for k, v in aws_ssm_parameter.service_role : k => v.arn
  }
} 