# CloudWatch Dashboard Terragrunt Module

This Terragrunt module reads dashboard configurations from JSON files and creates CloudWatch dashboards using the underlying CloudWatch module.

## Features

- **Dynamic JSON file discovery**: Automatically reads all `.json` files from the `dashboards/` directory
- **Zero-code changes**: Add new JSON files without modifying Terraform code
- **Template-based variable substitution**: Uses `templatefile()` for clean variable substitution
- Supports variable substitution in JSON files (${environment}, ${region}, ${project})
- Merges multiple JSON files into a single dashboard configuration
- Passes through all outputs from the underlying CloudWatch module

## Structure

```
terragrunt/
├── main.tf                    # Main module logic
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── README.md                  # This file
└── dashboards/                # JSON dashboard configurations
    ├── lambda-dashboards.json # Lambda monitoring dashboards
    └── sqs-dashboards.json    # SQS monitoring dashboards
```

## Usage

### Basic Usage

```hcl
module "cloudwatch_dashboards" {
  source = "./terraform/cloudwatch/terragrunt"
  
  region      = "us-east-1"
  environment = "prod"
  project     = "gas"
}
```

### With Terragrunt

```hcl
# terragrunt.hcl
terraform {
  source = "./terraform/cloudwatch/terragrunt"
}

inputs = {
  region      = "us-east-1"
  environment = "prod"
  project     = "gas"
}
```

## JSON File Format

The JSON files should contain a map of dashboard configurations. Each dashboard should have the following structure:

```json
{
  "dashboard_key": {
    "name": "dashboard-name-${environment}",
    "dashboard_body": {
      "widgets": [
        {
          "type": "metric",
          "x": 0,
          "y": 0,
          "width": 12,
          "height": 6,
          "properties": {
            "metrics": [
              ["AWS/Lambda", "Invocations", "FunctionName", "my-function"]
            ],
            "period": 300,
            "stat": "Sum",
            "region": "${region}",
            "title": "Lambda Invocations"
          }
        }
      ]
    },
    "tags": {
      "Environment": "${environment}",
      "Project": "${project}",
      "Service": "service-name"
    }
  }
}
```

**Note**: The `dashboard_body` is now a proper JSON object instead of a JSON string. The module automatically converts it to the required JSON string format using `jsonencode()`.

### Variable Substitution

The module uses Terraform's `templatefile()` function for variable substitution in JSON files. The following variables are available:

- `${environment}` - Replaced with the environment variable
- `${region}` - Replaced with the region variable  
- `${project}` - Replaced with the project variable

**Variable substitution works in all fields including:**
- Dashboard names
- Dashboard body properties (like region, titles, etc.)

### Example JSON File

```json
{
  "lambda_overview": {
    "name": "lambda-overview-${environment}",
    "dashboard_body": {
      "widgets": [
        {
          "type": "metric",
          "x": 0,
          "y": 0,
          "width": 12,
          "height": 6,
          "properties": {
            "metrics": [
              ["AWS/Lambda", "Invocations", "FunctionName", "my-function"]
            ],
            "period": 300,
            "stat": "Sum",
            "region": "${region}",
            "title": "Lambda Invocations"
          }
        }
      ]
    },

  }
}
```

**With variables `environment = "prod"`, `region = "us-east-1"`, `project = "gas"`, this becomes:**

```json
{
  "lambda_overview": {
    "name": "lambda-overview-prod",
    "dashboard_body": {
      "widgets": [
        {
          "type": "metric",
          "x": 0,
          "y": 0,
          "width": 12,
          "height": 6,
          "properties": {
            "metrics": [
              ["AWS/Lambda", "Invocations", "FunctionName", "my-function"]
            ],
            "period": 300,
            "stat": "Sum",
            "region": "us-east-1",
            "title": "Lambda Invocations"
          }
        }
      ]
    },

  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | AWS region for the CloudWatch dashboards | `string` | `"us-east-1"` | no |
| environment | Environment name for tagging | `string` | `"dev"` | no |
| project | Project name for tagging | `string` | `"gas"` | no |

## Outputs

| Name | Description |
|------|-------------|
| dashboard_names | Names of the created CloudWatch dashboards |
| dashboard_arns | ARNs of the created CloudWatch dashboards |
| dashboard_count | Number of CloudWatch dashboards created |
| dashboard_details | Detailed information about created CloudWatch dashboards |

## Adding New Dashboard Files

To add new dashboard configurations, simply create a new JSON file in the `dashboards/` directory:

1. Create a new JSON file in the `dashboards/` directory (e.g., `step-function-dashboards.json`)
2. Follow the JSON format described below
3. Run `terraform plan` or `terragrunt plan` - the new dashboards will be automatically discovered

**No code changes required!** The module automatically discovers and processes all `.json` files in the `dashboards/` directory.

## Included Dashboards

### Lambda Dashboards (`lambda-dashboards.json`)

- **lambda_overview**: Overview of all Lambda functions with invocations, errors, and duration
- **lambda_errors**: Focused view on Lambda errors and duration across all functions

### SQS Dashboards (`sqs-dashboards.json`)

- **sqs_overview**: Overview of SQS queues with message counts and performance metrics
- **sqs_performance**: Performance-focused view with message age, queue depth, and message size

## Notes

- JSON files must be valid JSON format
- Variable substitution happens before JSON parsing
- Dashboard names must be unique within your AWS account
- The module automatically discovers all `.json` files in the `dashboards/` directory
- All dashboard configurations are merged into a single configuration
- All outputs are passed through from the underlying CloudWatch module
- **No code changes required when adding new dashboard files** 