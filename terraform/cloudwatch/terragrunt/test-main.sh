#!/bin/bash

echo "🧪 Testing Main Module Fix"
echo "=========================="

echo ""
echo "1. Running terragrunt validate..."
if terragrunt validate-inputs >/dev/null 2>&1; then
    echo "   ✅ Validation passed"
else
    echo "   ❌ Validation failed"
    exit 1
fi

echo ""
echo "2. Running terragrunt plan..."
if terragrunt plan -out=main-test-plan.tfplan >/dev/null 2>&1; then
    echo "   ✅ Plan completed successfully"
else
    echo "   ❌ Plan failed"
    echo "   Error details:"
    terragrunt plan 2>&1 | head -10
    exit 1
fi

echo ""
echo "3. Checking for resources in plan..."
echo "   Total resources that would be created:"
terragrunt show main-test-plan.tfplan 2>/dev/null | grep -c "will be created" || echo "   0"

echo ""
echo "4. Checking debug outputs..."
echo "   All Alarms:"
terragrunt output debug_all_alarms 2>/dev/null | head -3

echo ""
echo "🎉 Main module test completed!"
echo ""
echo "If you see no errors above, the main module is working correctly."
echo ""
echo "Next steps:"
echo "1. Review the plan: terragrunt show main-test-plan.tfplan"
echo "2. Apply if happy: terragrunt apply main-test-plan.tfplan"



