# Test Lambda Module - Hash Generation Approach

This module demonstrates how to use the terraform-aws-lambda module with stable hash generation to prevent unnecessary Lambda function recreations in CI/CD environments.

## Problem Solved

The terraform-aws-lambda module uses internal `null_resource` with timestamp triggers that cause Lambda functions to be recreated on every deployment when the `.terragrunt-cache` folder is deleted (common in CI/CD).

## Solution

This module generates stable hashes for Lambda source files **outside** the terraform-aws-lambda module using a `before_hook`, then passes those hashes to the module via the `source_code_hash` parameter.

## How It Works

1. **Before Hook**: A bash script calculates SHA256 hashes of all Lambda source files
2. **Hash File**: Creates `lambda_hashes.json` with stable hashes
3. **Module Input**: Passes the pre-generated hashes to the terraform-aws-lambda module
4. **Stable Deployment**: Lambda functions only update when source code actually changes

## Directory Structure

```
test-lambda-module/
├── terragrunt.hcl          # Main configuration with hash generation
├── lambda-json/            # Lambda configuration files
│   └── test-lambda.json    # Test Lambda configuration
├── code/                   # Lambda source code
│   └── test-lambda.py      # Test Lambda function
└── README.md              # This file
```

## Testing

### Prerequisites

1. Terragrunt installed
2. AWS credentials configured
3. Terraform state backend configured

### Test Commands

```bash
# Initialize the module
terragrunt init

# Plan to see what would be created
terragrunt plan

# Apply to create the Lambda function
terragrunt apply

# Test cache deletion behavior
rm -rf .terragrunt-cache
terragrunt plan  # Should show no changes
```

### Expected Behavior

- **With cache**: Normal operation
- **Without cache**: Should show no changes (no Lambda recreation)
- **Source code change**: Should show Lambda update with new hash

## Key Features

1. **Stable Hashes**: Uses SHA256 of source files for consistent hashing
2. **CI/CD Friendly**: Works in environments where cache is deleted
3. **Source Code Tracking**: Only updates when source code actually changes
4. **Error Handling**: Graceful fallback if hash generation fails

## Hash File Format

The generated `lambda_hashes.json` file looks like:

```json
{
  "test-lambda": "sha256:abc123...",
  "another-lambda": "sha256:def456..."
}
```

## Customization

To use this approach in your own project:

1. Copy the `before_hook` from `terragrunt.hcl`
2. Adjust the file paths in the bash script
3. Update the `inputs` block to use the generated hashes
4. Ensure your Lambda JSON files match the expected format

## Troubleshooting

### Hash Generation Fails
- Check that source files exist in the expected locations
- Verify bash script has execute permissions
- Check file paths in the `before_hook`

### Still Getting Recreations
- Ensure `source_code_hash` is being passed correctly
- Check that the terraform-aws-lambda module version supports this approach
- Verify the hash file is being generated before the module runs

### CI/CD Issues
- Ensure the `before_hook` runs in your CI/CD environment
- Check that all required tools (sha256sum, sed) are available
- Verify file permissions in the CI/CD environment 