#!/usr/bin/env bash
set -euo pipefail

RG=${1:-my-mcp-rg}
LOCATION=${2:-eastus}
PREFIX=${3:-mcp}

echo "Creating resource group $RG in $LOCATION"
az group create -n "$RG" -l "$LOCATION"

echo "Deploying Bicep"
az deployment group create -g "$RG" --template-file main.bicep --parameters prefix=$PREFIX location=$LOCATION

echo "Deployment complete. To review outputs run: az deployment group show -g $RG --name "$(date +%Y%m%d%H%M%S)" --query properties.outputs -o json"
