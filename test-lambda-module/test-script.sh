#!/bin/bash

# Test script to demonstrate the hash generation approach
# This script simulates what the before_hook does

set -e

echo "=== Lambda Hash Generation Test ==="

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASH_FILE="${SCRIPT_DIR}/lambda_hashes.json"
CODE_DIR="${SCRIPT_DIR}/code"
JSON_DIR="${SCRIPT_DIR}/lambda-json"

echo "Script directory: $SCRIPT_DIR"
echo "Hash file: $HASH_FILE"
echo "Code directory: $CODE_DIR"
echo "JSON directory: $JSON_DIR"

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

# Calculate hashes for JSON files
for lambda in "$JSON_DIR"/*.json; do
    if [ -f "$lambda" ]; then
        lambda_name=$(basename "$lambda" .json)
        source_file="$CODE_DIR/$lambda_name.py"
        
        echo "Processing: $lambda_name"
        echo "  JSON file: $lambda"
        echo "  Source file: $source_file"
        
        if [ -f "$source_file" ]; then
            # Calculate SHA256 hash (use shasum for macOS compatibility)
            hash=$(shasum -a 256 "$source_file" | cut -d' ' -f1)
            echo "  \"$lambda_name\": \"$hash\"," >> "$HASH_FILE"
            echo "  Generated hash: $hash"
        else
            echo "  Warning: Source file not found: $source_file"
        fi
        echo ""
    fi
done

# Remove trailing comma and close JSON
# Use sed compatible with both Linux and macOS
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

# Test hash retrieval
echo "=== Testing Hash Retrieval ==="
if [ -f "$HASH_FILE" ]; then
    # Use jq if available, otherwise use grep/sed
    if command -v jq &> /dev/null; then
        echo "Using jq to parse hash file..."
        for lambda in "$JSON_DIR"/*.json; do
            if [ -f "$lambda" ]; then
                lambda_name=$(basename "$lambda" .json)
                hash=$(jq -r ".[\"$lambda_name\"]" "$HASH_FILE")
                echo "  $lambda_name: $hash"
            fi
        done
    else
        echo "jq not available, using grep/sed..."
        for lambda in "$JSON_DIR"/*.json; do
            if [ -f "$lambda" ]; then
                lambda_name=$(basename "$lambda" .json)
                hash=$(grep "\"$lambda_name\":" "$HASH_FILE" | sed 's/.*"\([^"]*\)".*/\1/')
                echo "  $lambda_name: $hash"
            fi
        done
    fi
else
    echo "Error: Hash file not created"
    exit 1
fi

echo ""
echo "=== Test Complete ==="
echo "You can now use this hash file with the terraform-aws-lambda module"
echo "The hash file will be stable as long as the source code doesn't change" 