#!/bin/bash

# Build script for Lambda packages
# This script builds Lambda packages and uploads them to S3

set -e

echo "=== Lambda Build Process ==="

# Configuration
# Use environment variables passed from Terragrunt, or fall back to relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASH_FILE="$SCRIPT_DIR/lambda_hashes.json"
BUILD_DIR="$SCRIPT_DIR/builds"

# Use command line arguments if provided, otherwise use relative paths
CODE_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)/code}"
JSON_DIR="${2:-$(cd "$SCRIPT_DIR/../.." && pwd)/lambda-json}"

echo "Script directory: $SCRIPT_DIR"
echo "Hash file: $HASH_FILE"
echo "Code directory: $CODE_DIR"
echo "JSON directory: $JSON_DIR"
echo "Build directory: $BUILD_DIR"

# Create build directory
mkdir -p "$BUILD_DIR"

# Check if directories exist
if [ ! -d "$CODE_DIR" ]; then
    echo "Error: Code directory not found: $CODE_DIR"
    exit 1
fi

if [ ! -d "$JSON_DIR" ]; then
    echo "Error: JSON directory not found: $JSON_DIR"
    exit 1
fi

# Generate hash file
echo "Generating lambda hashes..."
echo '{' > "$HASH_FILE"

# Process each JSON file
for lambda in "$JSON_DIR"/*.json; do
    if [ -f "$lambda" ]; then
        lambda_name=$(basename "$lambda" .json)
        source_file="$CODE_DIR/$lambda_name.py"
        
        echo "Processing: $lambda_name"
        echo "  JSON file: $lambda"
        echo "  Source file: $source_file"
        
        if [ -f "$source_file" ]; then
            # Calculate SHA256 hash
            hash=$(shasum -a 256 "$source_file" | cut -d' ' -f1)
            echo "  \"$lambda_name\": \"$hash\"," >> "$HASH_FILE"
            echo "  Generated hash: $hash"
            
            # Build package
            package_file="$BUILD_DIR/$lambda_name.zip"
            echo "  Building package: $package_file"
            
            # Create ZIP file
            cd "$CODE_DIR"
            zip -r "$package_file" "$lambda_name.py"
            cd - > /dev/null
            
            echo "  Package created: $package_file"
        else
            echo "  Warning: Source file not found: $source_file"
        fi
        echo ""
    fi
done

# Remove trailing comma and close JSON
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version
    sed -i '' '$ s/,$//' "$HASH_FILE"
else
    # Linux version
    sed -i '$ s/,$//' "$HASH_FILE"
fi
echo '}' >> "$HASH_FILE"

echo "Hash file created: $HASH_FILE"
echo ""
echo "Hash file contents:"
cat "$HASH_FILE"
echo ""

echo "=== Build Complete ==="
echo "Packages are ready in: $BUILD_DIR"
echo "Hash file is ready: $HASH_FILE" 