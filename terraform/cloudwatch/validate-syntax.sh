#!/bin/bash

echo "🔍 Validating Terraform Syntax"
echo "=============================="

echo ""
echo "1. Checking main.tf syntax..."

# Check for basic Terraform syntax issues
if grep -q "dynamic \"dimension\"" main.tf; then
    echo "   ❌ Found unsupported dimension dynamic block"
    exit 1
fi

if grep -q "dynamic \"threshold_metric_id\"" main.tf; then
    echo "   ❌ Found unsupported threshold_metric_id dynamic block"
    exit 1
fi

if grep -q "dynamic \"lambda_target\"" main.tf; then
    echo "   ❌ Found unsupported lambda_target dynamic block"
    exit 1
fi

if grep -q "tags.*aws_cloudwatch_dashboard" main.tf; then
    echo "   ❌ Found tags on aws_cloudwatch_dashboard (not supported)"
    exit 1
fi

echo "   ✅ No unsupported dynamic blocks found"
echo "   ✅ No unsupported tags found"

echo ""
echo "2. Checking locals.tf syntax..."

# Check for basic locals syntax
if ! grep -q "locals {" locals.tf; then
    echo "   ❌ No locals block found"
    exit 1
fi

if ! grep -q "all_alarms" locals.tf; then
    echo "   ❌ all_alarms local not found"
    exit 1
fi

if ! grep -q "log_metric_filters" locals.tf; then
    echo "   ❌ log_metric_filters local not found"
    exit 1
fi

echo "   ✅ Locals block found"
echo "   ✅ Required locals defined"

echo ""
echo "3. Checking resource references..."

# Check if main.tf references locals correctly
if ! grep -q "local.all_alarms" main.tf; then
    echo "   ❌ local.all_alarms not referenced in main.tf"
    exit 1
fi

if ! grep -q "local.log_metric_filters" main.tf; then
    echo "   ❌ local.log_metric_filters not referenced in main.tf"
    exit 1
fi

echo "   ✅ Local references found"

echo ""
echo "4. Checking file structure..."
echo "   main.tf: $(wc -l < main.tf) lines"
echo "   locals.tf: $(wc -l < locals.tf) lines"
echo "   variables.tf: $(wc -l < variables.tf) lines"
echo "   outputs.tf: $(wc -l < outputs.tf) lines"

echo ""
echo "5. Checking for common syntax errors..."

# Check for missing closing braces
main_braces=$(grep -o "{" main.tf | wc -l)
main_close_braces=$(grep -o "}" main.tf | wc -l)
locals_braces=$(grep -o "{" locals.tf | wc -l)
locals_close_braces=$(grep -o "}" locals.tf | wc -l)

if [ "$main_braces" != "$main_close_braces" ]; then
    echo "   ❌ Mismatched braces in main.tf ($main_braces open, $main_close_braces close)"
    exit 1
fi

if [ "$locals_braces" != "$locals_close_braces" ]; then
    echo "   ❌ Mismatched braces in locals.tf ($locals_braces open, $locals_close_braces close)"
    exit 1
fi

echo "   ✅ Braces are balanced"

echo ""
echo "🎉 Syntax validation completed successfully!"
echo ""
echo "✅ All checks passed:"
echo "   - No unsupported dynamic blocks"
echo "   - No unsupported tags"
echo "   - Required locals defined"
echo "   - Local references correct"
echo "   - Syntax appears valid"
echo ""
echo "📝 Note: This is a basic syntax check."
echo "   For full validation, run 'terraform validate' when tools are available."

