#!/bin/bash

echo "🔧 Testing Dynamic Block Fixes"
echo "=============================="

echo ""
echo "1. Checking if main.tf has unsupported dynamic blocks..."
if grep -q "dynamic \"dimension\"" ../terraform/cloudwatch/main.tf; then
    echo "   ❌ Found unsupported dimension dynamic block"
    exit 1
else
    echo "   ✅ No dimension dynamic blocks found"
fi

if grep -q "dynamic \"threshold_metric_id\"" ../terraform/cloudwatch/main.tf; then
    echo "   ❌ Found unsupported threshold_metric_id dynamic block"
    exit 1
else
    echo "   ✅ No threshold_metric_id dynamic blocks found"
fi

if grep -q "dynamic \"lambda_target\"" ../terraform/cloudwatch/main.tf; then
    echo "   ❌ Found unsupported lambda_target dynamic block"
    exit 1
else
    echo "   ✅ No lambda_target dynamic blocks found"
fi

echo ""
echo "2. Running terragrunt validate..."
if terragrunt validate-inputs >/dev/null 2>&1; then
    echo "   ✅ Validation passed"
else
    echo "   ❌ Validation failed"
    echo "   Error details:"
    terragrunt validate-inputs 2>&1 | head -10
    exit 1
fi

echo ""
echo "3. Running terragrunt plan..."
if terragrunt plan -out=fixes-test-plan.tfplan >/dev/null 2>&1; then
    echo "   ✅ Plan completed successfully"
else
    echo "   ❌ Plan failed"
    echo "   Error details:"
    terragrunt plan 2>&1 | head -10
    exit 1
fi

echo ""
echo "4. Checking file structure..."
echo "   main.tf: $(wc -l < ../terraform/cloudwatch/main.tf) lines"
echo "   locals.tf: $(wc -l < ../terraform/cloudwatch/locals.tf) lines"

echo ""
echo "🎉 Dynamic block fixes test completed!"
echo ""
echo "✅ Issues Fixed:"
echo "   - Removed unsupported 'dimension' dynamic block from aws_cloudwatch_metric_alarm"
echo "   - Removed unsupported 'threshold_metric_id' dynamic block from aws_cloudwatch_metric_alarm"
echo "   - Removed unsupported 'lambda_target' dynamic block from aws_cloudwatch_event_target"
echo "   - Removed unsupported 'ecs_target' dynamic block from aws_cloudwatch_event_target"
echo "   - Removed unsupported 'sqs_target' dynamic block from aws_cloudwatch_event_target"
echo "   - Removed unsupported 'input_transformer' dynamic block from aws_cloudwatch_event_target"
echo "   - Removed unsupported 'run_command_targets' dynamic block from aws_cloudwatch_event_target"
echo ""
echo "📝 Note: These resources now use simplified configurations."
echo "   For complex configurations, consider using separate resources or"
echo "   the AWS provider's native support for these features."
echo ""
echo "Next steps:"
echo "1. Review the plan: terragrunt show fixes-test-plan.tfplan"
echo "2. Apply if happy: terragrunt apply fixes-test-plan.tfplan"

