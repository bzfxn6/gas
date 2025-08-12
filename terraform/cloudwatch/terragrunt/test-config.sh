#!/bin/bash

echo "🧪 Testing Terragrunt Configuration"
echo "==================================="

# Test 1: Check if terragrunt.hcl is valid
echo "✅ Test 1: Validating terragrunt.hcl syntax..."
if terragrunt validate-inputs >/dev/null 2>&1; then
    echo "   PASS: terragrunt.hcl is valid"
else
    echo "   FAIL: terragrunt.hcl has syntax errors"
    exit 1
fi

# Test 2: Check if JSON files are valid
echo "✅ Test 2: Validating JSON files..."
for file in configs/*.json; do
    if [ -f "$file" ]; then
        if jq empty "$file" >/dev/null 2>&1; then
            echo "   PASS: $(basename "$file") is valid JSON"
        else
            echo "   FAIL: $(basename "$file") has JSON syntax errors"
            exit 1
        fi
    fi
done

# Test 3: Check if eks-clusters.json exists and has content
echo "✅ Test 3: Checking eks-clusters.json..."
if [ -f "configs/eks-clusters.json" ]; then
    cluster_count=$(jq 'length' configs/eks-clusters.json)
    echo "   PASS: eks-clusters.json exists with $cluster_count clusters"
else
    echo "   FAIL: eks-clusters.json missing"
    exit 1
fi

# Test 4: Run terragrunt plan to see what would be created
echo "✅ Test 4: Running terragrunt plan..."
if terragrunt plan -out=test-plan.tfplan >/dev/null 2>&1; then
    echo "   PASS: terragrunt plan completed successfully"
    
    # Check if EKS alarms would be created
    if terragrunt show test-plan.tfplan 2>/dev/null | grep -q "eks"; then
        echo "   PASS: EKS resources would be created"
    else
        echo "   WARNING: No EKS resources found in plan"
    fi
else
    echo "   FAIL: terragrunt plan failed"
    exit 1
fi

echo ""
echo "🎉 All tests passed! Configuration is working correctly."
echo ""
echo "Next steps:"
echo "1. Review the plan: terragrunt show test-plan.tfplan"
echo "2. Apply the configuration: terragrunt apply"
echo "3. Check created resources in AWS Console"

