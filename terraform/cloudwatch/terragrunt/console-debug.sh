#!/bin/bash

echo "🔍 Terragrunt Console Debugging"
echo "================================"

echo ""
echo "🚀 Starting Terragrunt Console..."
echo "Use these commands to debug:"
echo ""
echo "1. Check if JSON files are being read:"
echo "   local.eks_clusters_config"
echo ""
echo "2. Check the merged configuration:"
echo "   local.default_monitoring.eks_clusters"
echo ""
echo "3. Check all default monitoring:"
echo "   local.default_monitoring"
echo ""
echo "4. Check module inputs:"
echo "   module.cloudwatch.default_monitoring"
echo ""
echo "5. Check environment variables:"
echo "   local.environment"
echo "   local.customer"
echo "   local.team"
echo ""
echo "6. Check if any alarms would be created:"
echo "   local.all_alarms"
echo ""
echo "7. Exit console:"
echo "   exit"
echo ""
echo "Press Enter to start console..."
read

terragrunt console

