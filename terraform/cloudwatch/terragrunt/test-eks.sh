#!/bin/bash

echo "🧪 Testing EKS Cluster Monitoring"
echo "================================="

echo ""
echo "1. Checking JSON file..."
if [ -f "configs/eks-clusters.json" ]; then
    echo "   ✅ eks-clusters.json exists"
    echo "   Content:"
    cat configs/eks-clusters.json | jq '.' 2>/dev/null
else
    echo "   ❌ eks-clusters.json missing"
    exit 1
fi

echo ""
echo "2. Running terragrunt plan..."
if terragrunt plan -out=eks-test-plan.tfplan >/dev/null 2>&1; then
    echo "   ✅ Plan completed successfully"
else
    echo "   ❌ Plan failed"
    exit 1
fi

echo ""
echo "3. Checking debug outputs..."

echo "   JSON Config:"
terragrunt output debug_eks_clusters_config 2>/dev/null | head -5

echo "   Processed Config:"
terragrunt output debug_default_monitoring_eks_clusters 2>/dev/null | head -5

echo "   Generated Alarms:"
terragrunt output debug_eks_cluster_monitoring 2>/dev/null | head -5

echo "   All Alarms:"
terragrunt output debug_all_alarms 2>/dev/null | head -5

echo ""
echo "4. Checking plan for EKS resources..."
if terragrunt show eks-test-plan.tfplan 2>/dev/null | grep -q "eks"; then
    echo "   ✅ EKS resources found in plan"
    echo "   EKS resources that would be created:"
    terragrunt show eks-test-plan.tfplan 2>/dev/null | grep -i "eks" | head -5
else
    echo "   ❌ No EKS resources found in plan"
fi

echo ""
echo "🎯 Summary:"
echo "If you see EKS alarms in the outputs and plan, the configuration is working!"
echo "If you see empty outputs, there's still an issue to debug."
echo ""
echo "Next steps:"
echo "1. Review the plan: terragrunt show eks-test-plan.tfplan"
echo "2. Apply if happy: terragrunt apply eks-test-plan.tfplan"


