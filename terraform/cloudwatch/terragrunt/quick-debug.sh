#!/bin/bash

echo "🔍 Quick Terragrunt Debug"
echo "========================="

echo ""
echo "1. Checking JSON file reading..."
echo "local.eks_clusters_config" | terragrunt console 2>/dev/null | head -10

echo ""
echo "2. Checking merged configuration..."
echo "local.default_monitoring.eks_clusters" | terragrunt console 2>/dev/null | head -10

echo ""
echo "3. Checking environment variables..."
echo "local.environment" | terragrunt console 2>/dev/null
echo "local.customer" | terragrunt console 2>/dev/null
echo "local.team" | terragrunt console 2>/dev/null

echo ""
echo "4. Checking if any alarms would be created..."
echo "length(local.all_alarms)" | terragrunt console 2>/dev/null

echo ""
echo "5. Checking module inputs..."
echo "length(module.cloudwatch.default_monitoring.eks_clusters)" | terragrunt console 2>/dev/null

echo ""
echo "🔧 Manual Console Commands:"
echo "---------------------------"
echo "terragrunt console"
echo ""
echo "Then run these commands:"
echo "local.eks_clusters_config"
echo "local.default_monitoring.eks_clusters"
echo "local.all_alarms"
echo "module.cloudwatch.default_monitoring"



