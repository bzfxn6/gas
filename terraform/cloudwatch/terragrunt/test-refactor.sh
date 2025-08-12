#!/bin/bash

echo "🧪 Testing Refactoring to locals.tf"
echo "==================================="

echo ""
echo "1. Checking if locals.tf exists..."
if [ -f "../terraform/cloudwatch/locals.tf" ]; then
    echo "   ✅ locals.tf file exists"
else
    echo "   ❌ locals.tf file missing"
    exit 1
fi

echo ""
echo "2. Running terragrunt validate..."
if terragrunt validate-inputs >/dev/null 2>&1; then
    echo "   ✅ Validation passed"
else
    echo "   ❌ Validation failed"
    exit 1
fi

echo ""
echo "3. Running terragrunt plan..."
if terragrunt plan -out=refactor-test-plan.tfplan >/dev/null 2>&1; then
    echo "   ✅ Plan completed successfully"
else
    echo "   ❌ Plan failed"
    echo "   Error details:"
    terragrunt plan 2>&1 | head -10
    exit 1
fi

echo ""
echo "4. Checking file sizes..."
main_size=$(wc -l < ../terraform/cloudwatch/main.tf)
locals_size=$(wc -l < ../terraform/cloudwatch/locals.tf)
echo "   main.tf: $main_size lines"
echo "   locals.tf: $locals_size lines"

echo ""
echo "5. Checking debug outputs..."
echo "   All Alarms:"
terragrunt output debug_all_alarms 2>/dev/null | head -3

echo ""
echo "🎉 Refactoring test completed!"
echo ""
echo "✅ Benefits of the refactoring:"
echo "   - main.tf is now cleaner and focused on resources"
echo "   - locals.tf contains all the processing logic"
echo "   - Better separation of concerns"
echo "   - Easier to maintain and understand"
echo ""
echo "Next steps:"
echo "1. Review the plan: terragrunt show refactor-test-plan.tfplan"
echo "2. Apply if happy: terragrunt apply refactor-test-plan.tfplan"

