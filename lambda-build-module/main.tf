# S3 bucket for Lambda packages
resource "aws_s3_bucket" "lambda_packages" {
  bucket = var.lambda_packages_bucket

  tags = {
    Name        = var.lambda_packages_bucket
    Environment = "dev"
    Project     = "test-project"
    Component   = "lambda-packages"
    ManagedBy   = "terragrunt"
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "lambda_packages" {
  bucket = aws_s3_bucket.lambda_packages.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_packages" {
  bucket = aws_s3_bucket.lambda_packages.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "lambda_packages" {
  bucket = aws_s3_bucket.lambda_packages.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload Lambda packages to S3
resource "aws_s3_object" "lambda_packages" {
  for_each = var.lambdas

  bucket = aws_s3_bucket.lambda_packages.id
  key    = each.value.package_key
  source = "${path.module}/builds/${each.key}.zip"
  etag   = filemd5("${path.module}/builds/${each.key}.zip")

  tags = {
    Name        = "${each.key}-package"
    Environment = "dev"
    Project     = "test-project"
    Component   = "lambda-package"
    ManagedBy   = "terragrunt"
    Hash        = jsondecode(file(each.value.hash_file))[each.key]
  }
}

# Output the S3 bucket name and package URLs
output "lambda_packages_bucket" {
  description = "S3 bucket containing Lambda packages"
  value       = aws_s3_bucket.lambda_packages.id
}

output "lambda_packages" {
  description = "Lambda package S3 objects"
  value = {
    for k, v in aws_s3_object.lambda_packages : k => {
      bucket = v.bucket
      key    = v.key
      etag   = v.etag
      url    = "s3://${v.bucket}/${v.key}"
    }
  }
}

output "lambda_hashes" {
  description = "Lambda source code hashes"
  value = {
    for k, v in var.lambdas : k => jsondecode(file(v.hash_file))[k]
  }
} 