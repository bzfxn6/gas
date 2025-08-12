# CloudWatch Monitoring Configuration Files

This directory contains JSON configuration files for each AWS service that can be monitored by the CloudWatch module.

## 📁 File Structure

```
configs/
├── databases.json          # RDS database monitoring
├── lambdas.json           # Lambda function monitoring
├── sqs-queues.json        # SQS queue monitoring
├── ecs-services.json      # ECS service monitoring
├── eks-clusters.json      # EKS cluster monitoring
├── eks-pods.json          # EKS pod monitoring
├── eks-nodegroups.json    # EKS node group monitoring
├── step-functions.json    # Step Function monitoring
├── ec2-instances.json     # EC2 instance monitoring
├── s3-buckets.json        # S3 bucket monitoring
├── eventbridge-rules.json # EventBridge rule monitoring
├── log-alarms.json        # Log-based alarm monitoring (comprehensive examples)
└── log-alarms-simple.json # Log-based alarm monitoring (minimal examples)
```

## 🎯 Configuration Format

Each JSON file follows this structure:

```json
{
  "resource-key": {
    "name": "resource-name",
    "region": "us-east-1",
    "customer": "enbd-preprod",  // Optional - defaults to var.customer
    "team": "DNA",               // Optional - defaults to var.team
    "alarms": ["alarm1", "alarm2"],
    "exclude_alarms": ["alarm3"],
    "custom_alarms": {
      "custom-alarm-key": {
        "alarm_name": "Sev2/enbd-preprod/DNA/RDS/CPU/custom-alarm-name",
        "comparison_operator": "GreaterThanThreshold",
        "evaluation_periods": 1,
        "metric_name": "CustomMetric",
        "namespace": "AWS/Service",
        "period": 300,
        "statistic": "Average",
        "threshold": 80,
        "alarm_description": "Custom alarm description",
        "dimensions": [
          {
            "name": "DimensionName",
            "value": "dimension-value"
          }
        ]
      }
    }
  }
}
```

## 🏷️ **Standardized Alarm Naming Convention**

All alarms follow this standardized naming format:

```
{severity}/{customer}/{team}/{aws-service}/{sub-service}/{error-details}
```

### **Severity Levels**
- **Sev1** = High (Critical issues)
- **Sev2** = Medium (Warning issues)  
- **Sev3** = Low (Informational issues)
- **Sev4** = Info (Debugging issues)

### **Example Alarm Names**
```
Sev2/enbd-preprod/DNA/RDS/CPU/cpu-utilization-above-80%
Sev1/enbd-preprod/DNA/Lambda/Errors/function-errors-occurring
Sev3/enbd-preprod/DNA/EC2/filesystem/root-filesystem-above-95%
Sev2/enbd-preprod/DNA/SQS/QueueDepth/visible-messages-above-100
```

### **Configuration Variables**
- **customer**: Set in `terragrunt.hcl` (default: "enbd-preprod")
- **team**: Set in `terragrunt.hcl` (default: "DNA")
- **severity**: Determined by alarm type (high/medium/low/info)
- **aws-service**: AWS service name (RDS, Lambda, EC2, SQS, etc.)
- **sub-service**: Specific component (CPU, Memory, Errors, etc.)
- **error-details**: Descriptive error condition

## 🔧 Configuration Options

### **Required Fields**
- `name`: The name of the resource (will be appended with environment)

### **Optional Fields**
- `region`: AWS region (defaults to "us-east-1")
- `customer`: Customer for alarm naming (defaults to var.customer)
- `team`: Team for alarm naming (defaults to var.team)
- `alarms`: Array of alarm names to include (empty = all alarms)
- `exclude_alarms`: Array of alarm names to exclude
- `custom_alarms`: Map of custom alarm configurations

### **Service-Specific Fields**
- **ECS Services**: `cluster_name` (required)
- **EKS Pods**: `namespace`, `cluster_name` (required)
- **EC2 Instances**: `instance_id` (optional)

## 📊 Available Alarm Selections

### **Databases (RDS)**
- `cpu_utilization`, `memory_utilization`, `database_connections`
- `read_latency`, `write_latency`

### **Lambda Functions**
- `errors`, `duration`, `throttles`, `concurrent_executions`

### **SQS Queues**
- `queue_depth`, `message_age`, `error_rate`

### **ECS Services**
- `cpu_utilization`, `memory_utilization`, `running_task_count`

### **EC2 Instances**
- `cpu_utilization`, `network_in`, `network_out`, `status_check_failed`
- `disk_read_bytes`, `disk_write_bytes`, `ebs_read_bytes`, `ebs_write_bytes`
- And 15+ more alarms...

### **S3 Buckets**
- `bucket_size_bytes`, `number_of_objects`, `all_requests`
- `first_byte_latency`, `errors_4xx`, `errors_5xx`
- And 20+ more alarms...

### **EKS Clusters**
- `cluster_cpu_utilization`, `cluster_memory_utilization`, `cluster_node_count`
- And 10+ more alarms...

### **EKS Pods**
- `pod_cpu_utilization`, `pod_memory_utilization`, `pod_network_rx_bytes`
- And 8+ more alarms...

### **Step Functions**
- `execution_success_rate`, `execution_failure_rate`, `execution_time`
- And 20+ more alarms...

### **EventBridge Rules**
- `failed_invocations`, `dead_letter_invocations`, `delivery_failed`
- And 15+ more alarms...

## 🚀 Usage Examples

### **Simple Configuration**
```json
{
  "main-database": {
    "name": "main-database",
    "region": "us-east-1"
  }
}
```

**Generated Alarm Names:**
- `Sev2/enbd-preprod/DNA/RDS/CPU/cpu-utilization-above-80%`
- `Sev1/enbd-preprod/DNA/RDS/Memory/freeable-memory-below-1gb`
- `Sev2/enbd-preprod/DNA/RDS/Connections/database-connections-above-80`

### **Selective Alarm Monitoring**
```json
{
  "web-server": {
    "name": "web-server",
    "customer": "enbd-preprod",
    "team": "DNA",
    "alarms": ["cpu_utilization", "network_in", "network_out", "status_check_failed"],
    "exclude_alarms": ["disk_read_bytes", "disk_write_bytes"]
  }
}
```

### **Custom Alarms with Standardized Naming**
```json
{
  "api-function": {
    "name": "api-function",
    "customer": "enbd-preprod",
    "team": "DNA",
    "alarms": ["errors", "duration"],
    "custom_alarms": {
      "strict-error-rate": {
        "alarm_name": "Sev1/enbd-preprod/DNA/Lambda/Errors/strict-error-rate",
        "comparison_operator": "GreaterThanThreshold",
        "evaluation_periods": 1,
        "metric_name": "Errors",
        "namespace": "AWS/Lambda",
        "period": 300,
        "statistic": "Sum",
        "threshold": 0,
        "alarm_description": "API function has errors",
        "dimensions": [
          {
            "name": "FunctionName",
            "value": "api-function"
          }
        ]
      }
    }
  }
}
```

### **Different Customer/Team Override**
```json
{
  "production-db": {
    "name": "production-database",
    "customer": "enbd-prod",
    "team": "Platform",
    "alarms": ["cpu_utilization", "memory_utilization"]
  }
}
```

**Generated Alarm Names:**
- `Sev2/enbd-prod/Platform/RDS/CPU/cpu-utilization-above-80%`
- `Sev1/enbd-prod/Platform/RDS/Memory/freeable-memory-below-1gb`

## 🔄 Environment Variable Substitution

The Terragrunt configuration automatically appends the environment name to resource names:

```json
{
  "main-db": {
    "name": "main-database"
  }
}
```

Becomes: `main-database-production` (if environment is "production")

## 📝 Best Practices

1. **Use Descriptive Keys**: Use meaningful keys for your resources
2. **Group Related Resources**: Keep related resources in the same file
3. **Version Control**: Commit these files to version control for team collaboration
4. **Environment Separation**: Use different files or directories for different environments
5. **Documentation**: Add comments in your JSON files for complex configurations
6. **Testing**: Test your configurations in a staging environment first
7. **Consistent Naming**: Follow the standardized alarm naming convention for all custom alarms
8. **Severity Classification**: Use appropriate severity levels based on business impact

## 🛠️ Customization

You can modify these JSON files to:
- Add new resources
- Change alarm selections
- Add custom alarms with standardized naming
- Adjust thresholds
- Modify regions
- Override customer/team for specific resources

The Terragrunt configuration will automatically pick up changes when you run `terragrunt plan` or `terragrunt apply`.

## 📊 Log-Based Alarms Configuration

Log-based alarms allow you to create CloudWatch alarms from log patterns using metric filters and transformations.

### **Basic Log-Based Alarm Example**
```json
{
  "error-pattern": {
    "log_group_name": "/aws/lambda/api-function",
    "pattern": "[timestamp, level=ERROR, message]",
    "transformation_name": "ErrorCount",
    "transformation_namespace": "CustomMetrics",
    "transformation_value": "1",
    "default_value": "0",
    "alarm_description": "Error log pattern detected in API function logs",
    "comparison_operator": "GreaterThanThreshold",
    "evaluation_periods": 1,
    "period": 300,
    "statistic": "Sum",
    "threshold": 0,
    "treat_missing_data": "notBreaching",
    "unit": "Count",
    "severity": "Sev1",
    "sub_service": "Errors",
    "error_details": "error-log-pattern-detected",
    "customer": "enbd-preprod",
    "team": "DNA",
    "alarm_actions": ["arn:aws:sns:us-east-1:123456789012:alerts-topic"]
  }
}
```

### **Key Fields for Log-Based Alarms**

| Field | Description | Example |
|-------|-------------|---------|
| `log_group_name` | CloudWatch Log Group to monitor | `/aws/lambda/api-function` |
| `pattern` | Log pattern to match | `[timestamp, level=ERROR, message]` |
| `transformation_name` | Name for the extracted metric | `ErrorCount` |
| `transformation_namespace` | Namespace for the extracted metric | `CustomMetrics` |
| `transformation_value` | Value to extract from matched logs | `1` (for counting) |
| `default_value` | Default value when no logs match | `0` |
| `alarm_description` | Description of the alarm | `Error log pattern detected` |
| `comparison_operator` | Alarm comparison operator | `GreaterThanThreshold` |
| `evaluation_periods` | Number of evaluation periods | `1` |
| `period` | Evaluation period in seconds | `300` |
| `statistic` | Statistical function to apply | `Sum`, `Average` |
| `threshold` | Alarm threshold value | `0`, `5`, `10` |
| `treat_missing_data` | How to handle missing data | `notBreaching`, `breaching`, `ignore` |
| `unit` | Metric unit | `Count`, `Seconds` |
| `severity` | Alarm severity level | `Sev1`, `Sev2`, `Sev3`, `Sev4` |
| `sub_service` | Sub-service identifier | `Errors`, `Performance`, `Security` |
| `error_details` | Error details for alarm naming | `error-log-pattern-detected` |
| `customer` | Customer name | `enbd-preprod` |
| `team` | Team name | `DNA` |
| `alarm_actions` | SNS topic ARNs for notifications | `["arn:aws:sns:..."]` |

### **Generated Alarm Names**
Log-based alarms follow the same standardized naming convention:
```
Sev1/enbd-preprod/DNA/CloudWatch/Logs/Errors/error-log-pattern-detected
```

### **Common Log Pattern Examples**

**Lambda Error Logs:**
```json
{
  "lambda-errors": {
    "log_group_name": "/aws/lambda/api-function",
    "pattern": "[timestamp, level=ERROR, message]",
    "transformation_name": "LambdaErrorCount",
    "transformation_namespace": "CustomMetrics",
    "transformation_value": "1"
  }
}
```

**Application Load Balancer Access Logs:**
```json
{
  "alb-errors": {
    "log_group_name": "/aws/applicationloadbalancer/access-logs",
    "pattern": "[timestamp, client_ip, target_ip, request_processing_time, target_processing_time, response_processing_time, elb_status_code, target_status_code, received_bytes, sent_bytes, request, user_agent, ssl_cipher, ssl_protocol, target_group_arn, trace_id, domain_name, chosen_cert_arn, matched_rule_priority, request_creation_time, actions_executed, redirect_url, lambda_error_reason, target_port_list, target_status_code_list, classification, classification_reason]",
    "transformation_name": "ALBErrorCount",
    "transformation_namespace": "CustomMetrics",
    "transformation_value": "1"
  }
}
```

**RDS Error Logs:**
```json
{
  "db-errors": {
    "log_group_name": "/aws/rds/instance/main-database/error",
    "pattern": "[timestamp, level=ERROR, message=*connection*]",
    "transformation_name": "DBConnectionErrorCount",
    "transformation_namespace": "CustomMetrics",
    "transformation_value": "1"
  }
}
```

### **Simple Examples (log-alarms-simple.json)**

For quick setup, use the simple examples file with minimal required configuration:

```json
{
  "simple-error-pattern": {
    "log_group_name": "/aws/lambda/my-function",
    "pattern": "[timestamp, level=ERROR, message]",
    "transformation_name": "ErrorCount",
    "transformation_namespace": "CustomMetrics",
    "transformation_value": "1",
    "alarm_description": "Error log pattern detected",
    "comparison_operator": "GreaterThanThreshold",
    "evaluation_periods": 1,
    "period": 300,
    "statistic": "Sum",
    "threshold": 0
  }
}
```

**Generated Alarm Name:**
```
Sev2/enbd-preprod/DNA/CloudWatch/Logs/Custom/log-pattern-detected
```
