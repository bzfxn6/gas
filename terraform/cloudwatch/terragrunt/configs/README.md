# CloudWatch Configuration Files

This directory contains JSON configuration files for CloudWatch monitoring resources. The configuration system uses a clean, elegant for loop pattern with automatic file discovery and templatefile variable interpolation.

## Clean For Loop Pattern with Automatic File Discovery

The current `terragrunt.hcl` uses a clean, elegant for loop pattern that automatically discovers JSON files:

```hcl
# Module inputs
inputs = {
  # Clean, simple for loop pattern with automatic file discovery
  default_monitoring = merge(
    { for config_file in fileset("${get_terragrunt_dir()}/configs/global", "*.json") :
      trimsuffix(config_file, ".json") => jsondecode(templatefile("${get_terragrunt_dir()}/configs/global/${config_file}", {
        CUSTOMER     = local.customer
        TEAM         = local.team
        ENVIRONMENT  = local.environment
        REGION       = local.region
        PROJECT      = local.project
        RESOURCE_PREFIX = local.resource_prefix
        DEFAULT_ALARM_ACTIONS = join(",", try(split(",", get_env("DEFAULT_ALARM_ACTIONS", "")), []))
        DEFAULT_OK_ACTIONS = join(",", try(split(",", get_env("DEFAULT_OK_ACTIONS", "")), []))
        DEFAULT_INSUFFICIENT_DATA_ACTIONS = join(",", try(split(",", get_env("DEFAULT_INSUFFICIENT_DATA_ACTIONS", "")), []))
      }))
    },
    { for config_file in fileset("${get_terragrunt_dir()}/configs/local", "*.json") :
      trimsuffix(config_file, ".json") => jsondecode(templatefile("${get_terragrunt_dir()}/configs/local/${config_file}", {
        CUSTOMER     = local.customer
        TEAM         = local.team
        ENVIRONMENT  = local.environment
        REGION       = local.region
        PROJECT      = local.project
        RESOURCE_PREFIX = local.resource_prefix
        DEFAULT_ALARM_ACTIONS = join(",", try(split(",", get_env("DEFAULT_ALARM_ACTIONS", "")), []))
        DEFAULT_OK_ACTIONS = join(",", try(split(",", get_env("DEFAULT_OK_ACTIONS", "")), []))
        DEFAULT_INSUFFICIENT_DATA_ACTIONS = join(",", try(split(",", get_env("DEFAULT_INSUFFICIENT_DATA_ACTIONS", "")), []))
      }))
    },
    { for config_file in fileset("${get_terragrunt_dir()}/configs/${local.environment}", "*.json") :
      trimsuffix(config_file, ".json") => jsondecode(templatefile("${get_terragrunt_dir()}/configs/${local.environment}/${config_file}", {
        CUSTOMER     = local.customer
        TEAM         = local.team
        ENVIRONMENT  = local.environment
        REGION       = local.region
        PROJECT      = local.project
        RESOURCE_PREFIX = local.resource_prefix
        DEFAULT_ALARM_ACTIONS = join(",", try(split(",", get_env("DEFAULT_ALARM_ACTIONS", "")), []))
        DEFAULT_OK_ACTIONS = join(",", try(split(",", get_env("DEFAULT_OK_ACTIONS", "")), []))
        DEFAULT_INSUFFICIENT_DATA_ACTIONS = join(",", try(split(",", get_env("DEFAULT_INSUFFICIENT_DATA_ACTIONS", "")), []))
      }))
    }
  )
}
```

**Benefits of this approach:**
- ✅ **Automatic file discovery**: No need to manually list each JSON file
- ✅ **Templatefile support**: Variables like `${CUSTOMER}`, `${TEAM}` are interpolated
- ✅ **Graceful handling**: Missing files don't cause errors
- ✅ **Environment overrides**: Local and environment-specific files override global
- ✅ **Clean and simple**: Elegant pattern like your security group examples

## Using Dependencies (The Right Way)

You can now properly use Terragrunt dependencies to get values from other modules:

```hcl
# Define your dependencies
dependency "eks" {
  config_path = "../eks-cluster"
}

dependency "rds" {
  config_path = "../rds-database"
}

# Module inputs
inputs = {
  region = local.region
  environment = local.environment
  project = local.project
  
  # Override configurations with dependency values
  default_monitoring = {
    databases = {
      "main-database" = {
        name = dependency.rds.outputs.db_instance_id
        customer = local.customer
        team = local.team
        alarms = ["cpu_utilization", "free_storage_space"]
      }
    }
    lambdas = {}
    sqs_queues = {}
    ecs_services = {}
    eks_clusters = {
      "main-cluster" = {
        name = dependency.eks.outputs.cluster_name
        short_name = "main"  # Optional: adds short name to alarm names
        customer = local.customer
        team = local.team
        alarms = ["cpu_utilization", "memory_utilization"]
      }
    }
    eks_pods = {}
    eks_nodegroups = {}
    step_functions = {}
    ec2_instances = {}
    s3_buckets = {}
    eventbridge_rules = {}
    log_alarms = {}
  }
  
  dashboards = local.dashboards
  customer = local.customer
  team = local.team
  severity_levels = local.severity_levels
  common_tags = local.common_tags
}
```



## Reading JSON Files (Optional)

If you want to read JSON files, you can do it in the `inputs` block where dependencies are available:

```hcl
inputs = {
  # ... other inputs ...
  
  default_monitoring = merge(
    {
      # Your dependency-based configurations
      eks_clusters = {
        "main-cluster" = {
          name = dependency.eks.outputs.cluster_name
          customer = local.customer
          team = local.team
          alarms = ["cpu_utilization", "memory_utilization"]
        }
      }
    },
    # Read JSON files if needed
    {
      databases = try(jsondecode(file("${get_terragrunt_dir()}/configs/local/databases.json")), {})
      lambdas = try(jsondecode(file("${get_terragrunt_dir()}/configs/local/lambdas.json")), {})
    }
  )
}
```

## Templatefile Variable Interpolation

JSON configuration files support templatefile variable interpolation. Variables like `${CUSTOMER}`, `${TEAM}`, `${ENVIRONMENT}` are automatically replaced with actual values:

### Example JSON File with Variables

```json
{
  "example-database": {
    "name": "${RESOURCE_PREFIX}example-database",
    "customer": "${CUSTOMER}",
    "team": "${TEAM}",
    "environment": "${ENVIRONMENT}",
    "region": "${REGION}",
    "project": "${PROJECT}",
    "alarm_actions": ["${DEFAULT_ALARM_ACTIONS}"],
    "ok_actions": ["${DEFAULT_OK_ACTIONS}"],
    "insufficient_data_actions": ["${DEFAULT_INSUFFICIENT_DATA_ACTIONS}"],
    "custom_threshold": 85,
    "custom_description": "Example database for ${ENVIRONMENT} environment in ${REGION}"
  }
}
```

### Available Variables

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `${CUSTOMER}` | Customer name | `"enbd-preprod"` |
| `${TEAM}` | Team name | `"DNA"` |
| `${ENVIRONMENT}` | Environment name | `"production"` |
| `${REGION}` | AWS region | `"us-east-1"` |
| `${PROJECT}` | Project name | `"my-app"` |
| `${RESOURCE_PREFIX}` | Resource naming prefix | `"myapp-"` |
| `${DEFAULT_ALARM_ACTIONS}` | Default alarm action ARNs | `"arn:aws:sns:..."` |
| `${DEFAULT_OK_ACTIONS}` | Default OK action ARNs | `"arn:aws:sns:..."` |
| `${DEFAULT_INSUFFICIENT_DATA_ACTIONS}` | Default insufficient data action ARNs | `"arn:aws:sns:..."` |

### Benefits of Templatefile Variables

- ✅ **Dynamic configuration**: Same JSON file works across environments
- ✅ **Consistent naming**: All resources follow the same naming convention
- ✅ **Environment-specific values**: Different values for dev/staging/prod
- ✅ **Centralized control**: Change values in one place (environment variables)

## Environment Variables

```bash
# Set environment variables
export ENVIRONMENT="production"
export CUSTOMER="enbd-preprod"
export TEAM="DNA"
export RESOURCE_PREFIX="myapp"
export PROJECT="my-app"
export AWS_REGION="us-east-1"

# Default alarm actions (comma-separated ARNs)
export DEFAULT_ALARM_ACTIONS="arn:aws:sns:us-east-1:123456789012:alerts-topic,arn:aws:sns:us-east-1:123456789012:pagerduty-topic"
export DEFAULT_OK_ACTIONS="arn:aws:sns:us-east-1:123456789012:resolved-topic"
export DEFAULT_INSUFFICIENT_DATA_ACTIONS="arn:aws:sns:us-east-1:123456789012:insufficient-data-topic"

# Run terragrunt
terragrunt plan
```

## Default Alarm Actions

Configure default actions for all alarms using environment variables or direct configuration:

### Using Environment Variables

```bash
# Set default alarm actions via environment variables
export DEFAULT_ALARM_ACTIONS="arn:aws:sns:us-east-1:123456789012:alerts-topic,arn:aws:sns:us-east-1:123456789012:pagerduty-topic"
export DEFAULT_OK_ACTIONS="arn:aws:sns:us-east-1:123456789012:resolved-topic"
export DEFAULT_INSUFFICIENT_DATA_ACTIONS="arn:aws:sns:us-east-1:123456789012:insufficient-data-topic"
```

### Using Direct Configuration

```hcl
inputs = {
  # ... other inputs ...
  
  # Default alarm actions
  default_alarm_actions = [
    "arn:aws:sns:us-east-1:123456789012:alerts-topic",
    "arn:aws:sns:us-east-1:123456789012:pagerduty-topic"
  ]
  
  default_ok_actions = [
    "arn:aws:sns:us-east-1:123456789012:resolved-topic"
  ]
  
  default_insufficient_data_actions = [
    "arn:aws:sns:us-east-1:123456789012:insufficient-data-topic"
  ]
  
  # ... rest of configuration ...
}
```

### Overriding Default Actions for Specific Alarms

Individual alarms can override the default actions:

```hcl
inputs = {
  default_monitoring = {
    databases = {
      "critical-database" = {
        name = "critical-db"
        custom_alarms = {
          "high-cpu" = {
            alarm_name = "critical-db-high-cpu"
            # ... other alarm configuration ...
            alarm_actions = [
              "arn:aws:sns:us-east-1:123456789012:critical-alerts-topic",
              "arn:aws:sns:us-east-1:123456789012:emergency-topic"
            ]  # Overrides default actions for this specific alarm
          }
        }
      }
    }
  }
}
```

## Configuration Examples

### 1. Basic EKS Cluster with Dependencies

```hcl
dependency "eks" {
  config_path = "../eks-cluster"
}

inputs = {
  default_monitoring = {
    eks_clusters = {
      "main-cluster" = {
        name = dependency.eks.outputs.cluster_name
        short_name = "main"  # Optional: adds short name to alarm names
        customer = local.customer
        team = local.team
        alarms = ["cpu_utilization", "memory_utilization"]
        custom_alarms = {
          "high_pod_count" = {
            alarm_name = "Sev2/${local.customer}/${local.team}/EKS/main/Cluster/PodCount/pod-count-above-100"
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods = 2
            metric_name = "number_of_pods"
            namespace = "ContainerInsights"
            period = 300
            statistic = "Average"
            threshold = 100
            alarm_description = "EKS cluster pod count is above 100"
            treat_missing_data = "notBreaching"
            unit = "Count"
            dimensions = [
              {
                name = "ClusterName"
                value = dependency.eks.outputs.cluster_name
              }
            ]
          }
        }
      }
    }
  }
}
```

### 2. Multiple Resources with Dependencies

```hcl
dependency "eks" {
  config_path = "../eks-cluster"
}

dependency "rds" {
  config_path = "../rds-database"
}

dependency "lambda" {
  config_path = "../lambda-functions"
}

inputs = {
  default_monitoring = {
    databases = {
      "main-database" = {
        name = dependency.rds.outputs.db_instance_id
        customer = local.customer
        team = local.team
        alarms = ["cpu_utilization", "free_storage_space"]
      }
    }
    lambdas = {
      "api-function" = {
        name = dependency.lambda.outputs.function_name
        customer = local.customer
        team = local.team
        alarms = ["errors", "duration", "throttles"]
      }
    }
    eks_clusters = {
      "main-cluster" = {
        name = dependency.eks.outputs.cluster_name
        short_name = "main"  # Optional: adds short name to alarm names
        customer = local.customer
        team = local.team
        alarms = ["cpu_utilization", "memory_utilization"]
      }
    }
  }
}
```

## Benefits of This Approach

1. ✅ **Clean and Simple**: No complex JSON file reading logic
2. ✅ **Dependencies Work**: You can use `dependency.module.outputs` properly
3. ✅ **Flexible**: Easy to override configurations for different environments
4. ✅ **Maintainable**: Clear, readable configuration
5. ✅ **Environment Variables**: Still supports environment variable interpolation
6. ✅ **Optional JSON**: You can still read JSON files if needed
7. ✅ **Simple Overrides**: Powerful override system for customizing individual alarms
7. ✅ **Graceful Handling**: Missing JSON files don't cause errors
8. ✅ **Automatic Discovery**: No need to manually list each file
9. ✅ **Templatefile Support**: Variables are interpolated automatically

## Best Practices

1. **Use Dependencies for Dynamic Values**: Get resource names, ARNs, etc. from other modules
2. **Use Environment Variables for Static Values**: Customer, team, environment names
3. **Keep Configurations Simple**: Avoid complex logic in the terragrunt configuration
4. **Use JSON Files Sparingly**: Only when you need complex, reusable configurations
5. **Test Your Dependencies**: Always verify that dependency outputs are available
6. **Leverage Automatic File Discovery**: Add JSON files to the appropriate directories and they'll be picked up automatically
7. **Use Templatefile Variables**: Take advantage of variable interpolation in JSON files
8. **Missing Files Are OK**: The system gracefully handles missing JSON files without errors
9. **Use Simple Overrides**: Leverage the override system for environment-specific customizations

## Simple Override System

The module supports a powerful **simple override system** that allows you to customize individual alarm properties without redefining entire alarms. This is perfect for environment-specific configurations (dev vs prod) or customizing specific alarms.

### Basic Override Example

```json
{
  "my-eks-cluster": {
    "name": "my-eks-cluster",
    "short_name": "prod",
    "customer": "my-company",
    "team": "platform",
    "alarm_overrides": {
      "cpu_utilization": {
        "alarm_name": "Sev1/my-company/platform/EKS/prod/Cluster/CPU/cpu-utilization-above-70pct",
        "threshold": 70,
        "alarm_description": "Production EKS cluster CPU utilization is above 70%"
      }
    }
  }
}
```

### Environment-Specific Overrides

```json
// configs/global/eks-clusters.json (defaults)
{
  "my-eks-cluster": {
    "name": "my-eks-cluster",
    "short_name": "prod",
    "customer": "my-company",
    "team": "platform"
  }
}

// configs/local/eks-clusters.json (dev overrides)
{
  "my-eks-cluster": {
    "alarm_overrides": {
      "cpu_utilization": {
        "alarm_name": "Sev3/my-company/platform/EKS/dev/Cluster/CPU/cpu-utilization-above-90pct",
        "threshold": 90
      }
    }
  }
}
```

### Multiple Property Overrides

```json
{
  "my-database": {
    "name": "my-production-db",
    "customer": "my-company",
    "team": "platform",
    "alarm_overrides": {
      "cpu_utilization": {
        "alarm_name": "Sev1/my-company/platform/RDS/CPU/cpu-utilization-above-70pct",
        "threshold": 70,
        "evaluation_periods": 1,
        "alarm_description": "Production database CPU utilization is above 70%"
      },
      "memory_utilization": {
        "alarm_name": "Sev1/my-company/platform/RDS/Memory/memory-utilization-above-75pct",
        "threshold": 75
      }
    }
  }
}
```

### Benefits of the Override System

- ✅ **Simple configuration**: Just specify what you want to change
- ✅ **Defaults preserved**: Everything else uses the default configuration
- ✅ **Environment-specific**: Different settings for dev/prod/staging
- ✅ **Flexible**: Override any alarm property (threshold, description, evaluation_periods, etc.)
- ✅ **Clean JSON**: No need to duplicate entire alarm definitions
- ✅ **Maintainable**: Easy to update and version control

## Graceful Handling of Missing Files

The for loop pattern gracefully handles missing JSON files:

- **No Lambda file?** → System continues with just database alarms
- **No SQS file?** → System continues with other service alarms  
- **Empty directories?** → System continues with empty maps
- **Invalid JSON?** → Clear error message pointing to the specific file

**Example**: If you remove `configs/global/lambdas.json`, the plan will show:
- ✅ **9 database alarms** (from `databases.json`)
- ✅ **0 Lambda alarms** (empty map from missing file)
- ✅ **No errors** - clean execution continues

This makes it easy to:
- Add new service files incrementally
- Remove service files without breaking the system
- Test configurations with partial file sets

## Troubleshooting

### Dependency Not Found
- Check that the dependency path is correct
- Ensure the dependency module has been applied
- Verify the output name exists in the dependency module

### Configuration Not Applied
- Check that the resource type is correct (e.g., `eks_clusters`, not `eks_cluster`)
- Verify the configuration structure matches the expected format
- Ensure all required fields are provided

### Environment Variables Not Working
- Check that environment variables are set correctly
- Verify the variable names match what's expected in `locals`
- Use `terragrunt plan` to see the interpolated values
