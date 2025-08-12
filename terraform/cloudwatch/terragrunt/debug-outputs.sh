#!/bin/bash

echo "🔍 Debugging with Outputs"
echo "========================="

echo ""
echo "🚀 Running terragrunt plan to generate outputs..."
echo ""

# Run terragrunt plan to generate outputs
if terragrunt plan -out=debug-plan.tfplan >/dev/null 2>&1; then
    echo "✅ Plan completed successfully"
else
    echo "❌ Plan failed"
    exit 1
fi

echo ""
echo "📋 Checking Debug Outputs..."
echo "============================"

echo ""
echo "1. Environment Variables:"
terragrunt output debug_environment_vars 2>/dev/null | head -10

echo ""
echo "2. JSON File Contents (EKS Clusters):"
terragrunt output debug_eks_clusters_config 2>/dev/null | head -10

echo ""
echo "3. Processed EKS Clusters Config:"
terragrunt output debug_default_monitoring_eks_clusters 2>/dev/null | head -10

echo ""
echo "4. EKS Cluster Alarms Generated:"
terragrunt output debug_eks_cluster_monitoring 2>/dev/null | head -10

echo ""
echo "5. All Alarms That Would Be Created:"
terragrunt output debug_all_alarms 2>/dev/null | head -10

echo ""
echo "6. Module Inputs:"
terragrunt output debug_module_inputs 2>/dev/null | head -10

echo ""
echo "🔧 Manual Commands:"
echo "------------------"
echo "To see specific outputs:"
echo "  terragrunt output debug_eks_clusters_config"
echo "  terragrunt output debug_eks_cluster_monitoring"
echo "  terragrunt output debug_all_alarms"
echo ""
echo "To see the full plan:"
echo "  terragrunt show debug-plan.tfplan"
echo ""
echo "To apply if everything looks good:"
echo "  terragrunt apply debug-plan.tfplan"

