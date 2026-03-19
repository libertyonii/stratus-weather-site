#!/usr/bin/env bash
# Usage: ./provision-and-deploy.sh [--destroy]
# Prerequisites: Azure CLI installed and logged in via: az login

set -euo pipefail

# ── Config — edit these ───────────────────────────────────────────────────────
RESOURCE_GROUP="stratus-static-site-rg"
LOCATION="southafricanorth"
STORAGE_ACCOUNT="stratusweather$(date +%s | tail -c 6)"   # globally unique name
WEBSITE_DIR="$(cd "$(dirname "$0")/../website" && pwd)"

# ── Destroy mode ──────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--destroy" ]]; then
  az group delete --name "$RESOURCE_GROUP" --yes --no-wait
  echo "Deletion initiated."; exit 0
fi

# ── Preflight checks ──────────────────────────────────────────────────────────
command -v az &>/dev/null || { echo "Azure CLI not found."; exit 1; }
az account show &>/dev/null || { echo "Not logged in. Run: az login"; exit 1; }
[[ -f "$WEBSITE_DIR/index.html" ]] || { echo "index.html not found in $WEBSITE_DIR"; exit 1; }

# ── Resource Group ────────────────────────────────────────────────────────────
az group show --name "$RESOURCE_GROUP" &>/dev/null \
  || az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# ── Storage Account ───────────────────────────────────────────────────────────
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access true \
  --min-tls-version TLS1_2 \
  --output none

# ── Enable Static Website Hosting ─────────────────────────────────────────────
az storage blob service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --static-website \
  --index-document "index.html" \
  --404-document "404.html" \
  --output none

# ── Upload Website Files ──────────────────────────────────────────────────────
ACCOUNT_KEY=$(az storage account keys list \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "[0].value" -o tsv)

az storage blob upload-batch \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --source "$WEBSITE_DIR" \
  --destination '$web' \
  --overwrite \
  --output none

# ── Done ──────────────────────────────────────────────────────────────────────
URL=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "primaryEndpoints.web" -o tsv)

echo "✅ Stratus is live: $URL"
echo "   Storage Account: $STORAGE_ACCOUNT"
echo "   To tear down: ./provision-and-deploy.sh --destroy"
