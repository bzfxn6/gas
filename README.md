# Lambda Deployment with Two-Module Architecture

This repository contains a two-module approach for Lambda deployment that separates build and deployment concerns:

## Architecture

### 1. **Build Module** (`lambda-build-module/`)
- **Purpose**: Builds Lambda packages and uploads them to S3
- **Pipeline**: Build → Package → Upload to S3
- **Triggers**: Source code changes, dependency updates
- **Outputs**: S3 bucket with Lambda packages and their hashes

### 2. **Deploy Module** (`lambda-deploy-module/`)
- **Purpose**: Deploys Lambda functions from S3 packages
- **Pipeline**: Deploy from S3 → Create Lambda functions
- **Triggers**: S3 package changes (hash changes)
- **Outputs**: Deployed Lambda functions with IAM roles and CloudWatch logs

## Benefits

✅ **Separated Concerns**: Build and deployment are independent  
✅ **Faster Deployments**: Only deploy when packages change  
✅ **Parallel Pipelines**: Build and deploy can run independently  
✅ **Hash-Based Updates**: Only update Lambda when source code changes  
✅ **Cache Resilient**: Works correctly when `.terragrunt-cache` is deleted  

## Usage

### Build Pipeline (CI/CD 1)
```bash
cd lambda-build-module
terragrunt plan
terragrunt apply
```

### Deploy Pipeline (CI/CD 2)
```bash
cd lambda-deploy-module
terragrunt plan
terragrunt apply
```

## File Structure

```
├── lambda-build-module/          # Build and package Lambda functions
│   ├── terragrunt.hcl           # Build module configuration
│   ├── main.tf                  # S3 bucket and package upload
│   ├── variables.tf             # Build module variables
│   └── build-script.sh          # Build script (generates hashes + packages)
│
├── lambda-deploy-module/         # Deploy Lambda functions from S3
│   ├── terragrunt.hcl           # Deploy module configuration
│   ├── main.tf                  # Lambda functions, IAM roles, CloudWatch
│   └── variables.tf             # Deploy module variables
│
├── lambda-json/                  # Lambda configurations (shared)
│   └── test-lambda-hash-demo-2.json
│
├── code/                         # Lambda source code (shared)
│   └── test-lambda-hash-demo-2.py
│
└── test-lambda-module/           # Original single-module approach (for reference)
```

## How It Works

1. **Build Process**:
   - `build-script.sh` generates hashes of source files
   - Creates ZIP packages for each Lambda
   - Uploads packages to S3 with hash metadata
   - Outputs package locations and hashes

2. **Deploy Process**:
   - Reads package locations from build module outputs
   - Creates Lambda functions using S3 packages
   - Uses hashes to determine if updates are needed
   - Only updates Lambda when hash changes

## Hash-Based Updates

- **Source code unchanged** → Hash unchanged → No Lambda update
- **Source code changed** → Hash changed → Lambda updated
- **Cache deleted** → Hash regenerated (same value) → No unnecessary updates

## CI/CD Integration

### Build Pipeline
```yaml
# Trigger on source code changes
on:
  push:
    paths:
      - 'code/**'
      - 'lambda-json/**'
      - 'lambda-build-module/**'

steps:
  - name: Build Lambda Packages
    run: |
      cd lambda-build-module
      terragrunt apply --auto-approve
```

### Deploy Pipeline
```yaml
# Trigger on build completion or manual
on:
  workflow_run:
    workflows: ["Build Lambda Packages"]
    types: [completed]

steps:
  - name: Deploy Lambda Functions
    run: |
      cd lambda-deploy-module
      terragrunt apply --auto-approve
```

## State Management

Both modules use remote state in S3:
- **Build state**: `terraform-state-gas-test-904233119504/lambda-build-module/terraform.tfstate`
- **Deploy state**: `terraform-state-gas-test-904233119504/lambda-deploy-module/terraform.tfstate`

This ensures state persistence even when `.terragrunt-cache` is deleted.