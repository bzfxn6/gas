# GitHub Workflows

This directory contains GitHub Actions workflows for automated infrastructure management.

## PowerSave Workflows

This directory contains two complementary workflows for managing resource power states to save costs:

### 1. PowerSave Shutdown Workflow

The `powersave-shutdown.yml` workflow automatically powers off Aurora PostgreSQL databases and EC2 instances that have specific tags to save costs during off-hours.

### 2. PowerSave Startup Workflow

The `powersave-startup.yml` workflow manually powers on the same Aurora PostgreSQL databases and EC2 instances when needed during business hours. It supports the same multi-environment functionality as the shutdown workflow.

### Features

- **Scheduled Execution**: Runs daily at 20:00 UTC
- **Manual Trigger**: Can be triggered manually with custom parameters
- **Multi-Environment Support**: Automatically processes all three environments (gss/sandbox, gss/dev, gss/int)
- **Environment Selection**: Can target specific environments or all environments
- **Parallel Processing**: Uses GitHub Actions matrix strategy for concurrent environment processing
- **Dedicated Runners**: Each environment runs on its own dedicated runner for maximum efficiency
- **Dry Run Mode**: Test the workflow without actually stopping resources
- **Multi-Region Support**: Supports multiple AWS regions
- **Comprehensive Logging**: Detailed logs and summary reports

### Prerequisites

1. **AWS Role Setup**: The workflows require AWS IAM roles for each environment with the following permissions:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "rds:DescribeDBClusters",
           "rds:ListTagsForResource",
           "rds:StopDBCluster",
           "rds:StartDBCluster",
           "ec2:DescribeInstances",
           "ec2:StopInstances",
           "ec2:StartInstances",
           "sts:AssumeRole"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

2. **Environment Configuration**: Each environment should have an `accounts.hcl` file at `terraform/{environment}/accounts.hcl` with the AWS account number:
   ```hcl
   locals {
     aws_account_number = "123456789012"
   }
   ```

3. **IAM Roles**: Each environment should have a role named `{environment}-gss-tuning-runner-ro-ci-role` (e.g., `gss-sandbox-gss-tuning-runner-ro-ci-role`)

### Resource Tagging

To include resources in the power save shutdown, tag them with:
- `team = dna`
- `powersave = true`

Example AWS CLI commands to tag resources:

```bash
# Tag Aurora PostgreSQL cluster
aws rds add-tags-to-resource \
  --resource-name "arn:aws:rds:region:account:cluster:cluster-name" \
  --tags Key=team,Value=dna Key=powersave,Value=true

# Tag EC2 instance
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=team,Value=dna Key=powersave,Value=true
```

### Usage

#### Shutdown Workflow
**Automatic Execution**: Runs automatically every day at 20:00 UTC, processing all environments.

**Manual Execution**:
1. Go to the Actions tab in your GitHub repository
2. Select "PowerSave Shutdown" workflow
3. Click "Run workflow"
4. Choose your desired parameters:
   - **AWS Region**: Select the region to operate in
   - **Environment**: Choose specific environment or "all" for all environments
   - **Dry Run**: Enable to test without stopping resources

#### Startup Workflow
**Manual Execution Only**:
1. Go to the Actions tab in your GitHub repository
2. Select "PowerSave Startup" workflow
3. Click "Run workflow"
4. Choose your desired parameters:
   - **AWS Region**: Select the region to operate in
   - **Environment**: Choose specific environment or "all" for all environments
   - **Resource Type**: Choose to start all resources, only Aurora clusters, or only EC2 instances
   - **Dry Run**: Enable to test without starting resources

### Output

Both workflows provide:
- Detailed logs for each step, organized by environment
- Summary report showing which resources were affected in each environment
- GitHub step summary with execution details
- Resource status monitoring (startup workflow waits for Aurora clusters to become available)
- Environment-specific resource tracking

### Safety Features

- **Status Checking**: Only affects resources in the appropriate state (running for shutdown, stopped for startup)
- **Tag Validation**: Verifies both required tags are present
- **Environment Isolation**: Each environment is processed independently with its own AWS credentials
- **Parallel Execution**: Environments run concurrently on separate runners for faster processing
- **Fail-Fast Control**: Matrix strategy with `fail-fast: false` ensures one environment failure doesn't stop others
- **Dry Run Mode**: Test functionality without making changes
- **Comprehensive Logging**: Full audit trail of all actions, organized by environment
- **Resource Type Selection**: Startup workflow allows targeting specific resource types
- **Startup Monitoring**: Waits for Aurora clusters to become available after starting
- **Error Handling**: If one environment fails, others continue processing

### Monitoring

Monitor the workflow execution in:
- GitHub Actions tab (each environment has its own job with detailed logs)
- AWS CloudWatch logs (if configured)
- Resource status in AWS Console
- Individual environment summaries in GitHub step summaries

### Troubleshooting

Common issues and solutions:

1. **Permission Denied**: Ensure the AWS role has the required permissions
2. **No Resources Found**: Verify resources are tagged correctly
3. **Region Issues**: Check that the specified region contains the resources
4. **Workflow Fails**: Check the GitHub Actions logs for detailed error messages

### Cost Impact

- **Aurora PostgreSQL**: Stopping clusters reduces compute costs but retains storage costs
- **EC2 Instances**: Stopping instances reduces compute costs but retains EBS storage costs
- **Startup Time**: Aurora clusters may take several minutes to become available after starting
- **Manual Control**: Startup workflow provides full control over when resources are brought back online

### Best Practices

1. **Test First**: Always use dry run mode before enabling automatic execution
2. **Monitor**: Regularly check workflow execution and resource status
3. **Document**: Keep track of which resources are included in power save
4. **Backup**: Ensure critical data is backed up before enabling automatic shutdown
5. **Startup Planning**: Plan ahead for when you'll need resources back online
6. **Team Communication**: Coordinate with your team about power save schedules 