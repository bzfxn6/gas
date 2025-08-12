# CloudWatch Configuration Files

This directory contains JSON configuration files for CloudWatch monitoring resources. The configuration system is now clean and simple, allowing you to use dependencies properly.

## Simple Approach

The current `terragrunt.hcl` uses a clean, simple approach:

```hcl
# Module inputs
inputs = {
  # Simple configuration - you can override these with dependencies or direct values
  default_monitoring = {
    databases = {}
    lambdas = {}
    sqs_queues = {}
    ecs_services = {}
    eks_clusters = {}
    eks_pods = {}
    eks_nodegroups = {}
    step_functions = {}
    ec2_instances = {}
    s3_buckets = {}
    eventbridge_rules = {}
    log_alarms = {}
  }
}
```

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

## Environment Variables

You can control the configuration using environment variables:

```bash
# Set environment variables
export ENVIRONMENT="production"
export CUSTOMER="enbd-preprod"
export TEAM="DNA"
export RESOURCE_PREFIX="myapp"
export PROJECT="my-app"
export AWS_REGION="us-east-1"

# Run terragrunt
terragrunt plan
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
        customer = local.customer
        team = local.team
        alarms = ["cpu_utilization", "memory_utilization"]
        custom_alarms = {
          "high_pod_count" = {
            alarm_name = "Sev2/${local.customer}/${local.team}/EKS/Cluster/PodCount/pod-count-above-100"
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

## Best Practices

1. **Use Dependencies for Dynamic Values**: Get resource names, ARNs, etc. from other modules
2. **Use Environment Variables for Static Values**: Customer, team, environment names
3. **Keep Configurations Simple**: Avoid complex logic in the terragrunt configuration
4. **Use JSON Files Sparingly**: Only when you need complex, reusable configurations
5. **Test Your Dependencies**: Always verify that dependency outputs are available

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
