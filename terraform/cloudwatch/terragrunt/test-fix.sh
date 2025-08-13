#!/bin/bash

echo "🔧 Testing evaluation_periods Fix"
echo "================================"

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
if terragrunt plan -out=fix-test-plan.tfplan >/dev/null 2>&1; then
    echo "   ✅ Plan completed successfully"
else
    echo "   ❌ Plan failed"
    echo "   Error details:"
    terragrunt plan 2>&1 | grep -A 5 -B 5 "evaluation_periods"
    exit 1
fi

echo ""
echo "3. Checking for EKS alarms..."
if terragrunt show fix-test-plan.tfplan 2>/dev/null | grep -q "eks"; then
    echo "   ✅ EKS alarms found in plan"
    echo "   EKS alarms that would be created:"
    terragrunt show fix-test-plan.tfplan 2>/dev/null | grep -i "eks" | head -5
else
    echo "   ⚠️  No EKS alarms found (this might be normal if no EKS clusters configured)"
fi

echo ""
echo "4. Checking debug outputs..."
echo "   EKS Cluster Alarms:"
terragrunt output debug_eks_cluster_monitoring 2>/dev/null | head -3

echo ""
echo "🎉 Fix test completed!"
echo ""
echo "If you see no errors above, the evaluation_periods issue is fixed."
echo ""
echo "Next steps:"
echo "1. Review the plan: terragrunt show fix-test-plan.tfplan"
echo "2. Apply if happy: terragrunt apply fix-test-plan.tfplan"



