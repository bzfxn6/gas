#!/bin/bash

echo "🧪 Testing JSON File Reading"
echo "============================"

# Test 1: Check if file exists
echo "1. Checking if eks-clusters.json exists..."
if [ -f "configs/eks-clusters.json" ]; then
    echo "   ✅ File exists"
else
    echo "   ❌ File missing"
    exit 1
fi

# Test 2: Check JSON syntax
echo "2. Checking JSON syntax..."
if jq empty configs/eks-clusters.json 2>/dev/null; then
    echo "   ✅ JSON syntax is valid"
else
    echo "   ❌ JSON syntax error"
    exit 1
fi

# Test 3: Check content
echo "3. Checking JSON content..."
echo "   File content:"
cat configs/eks-clusters.json | jq '.' 2>/dev/null

# Test 4: Check cluster count
echo "4. Checking cluster count..."
cluster_count=$(jq 'length' configs/eks-clusters.json 2>/dev/null)
echo "   Found $cluster_count clusters"

# Test 5: Check cluster names
echo "5. Checking cluster names..."
jq 'keys[]' configs/eks-clusters.json 2>/dev/null

# Test 6: Check if Terragrunt can read it
echo "6. Testing Terragrunt JSON reading..."
echo "   Running: echo 'local.eks_clusters_config' | terragrunt console"
echo "local.eks_clusters_config" | terragrunt console 2>&1 | head -5

echo ""
echo "🎯 Next Steps:"
echo "1. Run: ./console-debug.sh"
echo "2. In console, type: local.eks_clusters_config"
echo "3. Check if the output matches your JSON file"



