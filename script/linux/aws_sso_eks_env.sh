#!/bin/bash

# Usage: ./aws_sso_eks_env.sh <json_file> <env> [workspace]

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <json_file> <env> [workspace]"
  exit 1
fi

JSON_FILE="$1"
ENV="$2"
CLUSTER_CHOICE="${3:-c}"

if ! command -v jq &> /dev/null; then
  echo "jq is required but not installed. Please install jq."
  exit 1
fi

if [ "$CLUSTER_CHOICE" != "c" ] && [ "$CLUSTER_CHOICE" != "w" ]; then
  echo "Invalid workspace choice. Use 'c' or 'w'."
  exit 1
fi

PROFILE=$(jq -r --arg env "$ENV" '.[$env].profile' "$JSON_FILE")
EKS_CLUSTER=$(jq -r --arg env "$ENV" --arg ws "$CLUSTER_CHOICE" '.[$env]["eks_cluster_" + $ws]' "$JSON_FILE")

if [ "$PROFILE" == "null" ] || [ -z "$PROFILE" ]; then
  echo "Error: 'profile' not found for environment '$ENV' in $JSON_FILE"
  exit 1
fi

if [ "$EKS_CLUSTER" == "null" ] || [ -z "$EKS_CLUSTER" ]; then
  echo "Error: EKS cluster name not found for workspace '$CLUSTER_CHOICE' in environment '$ENV' in $JSON_FILE"
  exit 1
fi

# Login to AWS SSO
aws sso login --profile "$PROFILE"

# Update kubeconfig for EKS
aws eks update-kubeconfig --name "$EKS_CLUSTER" --profile "$PROFILE"

# Export AWS_PROFILE in current shell
export AWS_PROFILE="$PROFILE"
echo "export AWS_PROFILE=\"$PROFILE\"" >> ~/.bashrc

echo "AWS_PROFILE set to $PROFILE and added to ~/.bashrc."
echo "EKS kubeconfig updated for cluster $EKS_CLUSTER." 