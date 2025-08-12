#!/bin/bash

# Debug script to check Terragrunt configuration
echo "🔍 Debugging Terragrunt Configuration"
echo "====================================="

# Check if we're in the right directory
if [ ! -f "terragrunt.hcl" ]; then
    echo "❌ Error: terragrunt.hcl not found in current directory"
    echo "Please run this script from the terragrunt directory"
    exit 1
fi

echo "✅ Found terragrunt.hcl"

# Check if configs directory exists
if [ ! -d "configs" ]; then
    echo "❌ Error: configs directory not found"
    echo "Creating configs directory..."
    mkdir -p configs
fi

echo "✅ Configs directory exists"

# List all JSON files
echo ""
echo "📁 JSON Configuration Files:"
echo "----------------------------"
for file in configs/*.json; do
    if [ -f "$file" ]; then
        echo "✅ $(basename "$file")"
        echo "   Content preview:"
        head -5 "$file" | sed 's/^/   /'
        echo ""
    else
        echo "❌ No JSON files found in configs/"
        break
    fi
done

# Check specific files
echo "🔍 Checking Specific Files:"
echo "---------------------------"

# Check eks-clusters.json
if [ -f "configs/eks-clusters.json" ]; then
    echo "✅ eks-clusters.json exists"
    echo "   Content:"
    cat "configs/eks-clusters.json" | jq '.' 2>/dev/null || echo "   (Not valid JSON)"
else
    echo "❌ eks-clusters.json missing"
fi

echo ""
echo "🚀 Running Terragrunt Validate..."
echo "--------------------------------"

# Run terragrunt validate
terragrunt validate-inputs 2>&1 | head -20

echo ""
echo "📋 Running Terragrunt Plan (dry run)..."
echo "---------------------------------------"

# Run terragrunt plan to see what would be created
terragrunt plan -out=debug-plan.tfplan 2>&1 | grep -E "(eks_clusters|EKS|Plan:|No changes|Error)" | head -10

echo ""
echo "🔧 Debug Commands:"
echo "------------------"
echo "To see all locals: terragrunt console"
echo "To see specific local: terragrunt console -var='local.eks_clusters_config'"
echo "To see module inputs: terragrunt console -var='module.cloudwatch.default_monitoring'"
echo ""
echo "To run full plan: terragrunt plan"
echo "To apply: terragrunt apply"

