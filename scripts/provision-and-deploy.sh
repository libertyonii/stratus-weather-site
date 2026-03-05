#!/usr/bin/env bash
# =============================================================================
# Aurora Studio — Azure Static Website Provisioning & Deployment Script
# =============================================================================
# Usage:
#   chmod +x provision-and-deploy.sh
#   ./provision-and-deploy.sh [--destroy]
#
# Prerequisites:
#   - Azure CLI installed  (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
#   - Logged in via:       az login
# =============================================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}\n"; }

# ── Configuration — edit these ────────────────────────────────────────────────
RESOURCE_GROUP="aurora-static-site-rg"
LOCATION="eastus"                          # az account list-locations -o table
STORAGE_ACCOUNT="aurorastudio$(date +%s | tail -c 6)"  # must be globally unique, 3-24 lower-alphanum
SKU="Standard_LRS"                         # Locally-redundant storage (cheapest)
WEBSITE_DIR="$(cd "$(dirname "$0")/../website" && pwd)"
INDEX_DOC="index.html"
ERROR_DOC="404.html"

# ── Destroy mode ──────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--destroy" ]]; then
  warn "Destroying resource group: $RESOURCE_GROUP"
  az group delete --name "$RESOURCE_GROUP" --yes --no-wait
  success "Deletion initiated (runs in background)."
  exit 0
fi

# ── Preflight checks ──────────────────────────────────────────────────────────
header "Preflight Checks"

command -v az &>/dev/null || error "Azure CLI not found. Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"

ACCOUNT=$(az account show --query "user.name" -o tsv 2>/dev/null) \
  || error "Not logged in to Azure. Run: az login"
success "Logged in as: $ACCOUNT"

[[ -d "$WEBSITE_DIR" ]] || error "Website directory not found: $WEBSITE_DIR"
[[ -f "$WEBSITE_DIR/$INDEX_DOC" ]] || error "index.html not found in: $WEBSITE_DIR"
success "Website source found: $WEBSITE_DIR"

# ── Resource Group ────────────────────────────────────────────────────────────
header "Resource Group"

if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
  warn "Resource group '$RESOURCE_GROUP' already exists — skipping creation."
else
  info "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none
  success "Resource group created."
fi

# ── Storage Account ───────────────────────────────────────────────────────────
header "Storage Account"

info "Creating storage account '$STORAGE_ACCOUNT' (SKU: $SKU)..."
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku "$SKU" \
  --kind StorageV2 \
  --allow-blob-public-access true \
  --min-tls-version TLS1_2 \
  --output none
success "Storage account created: $STORAGE_ACCOUNT"

# ── Enable Static Website Hosting ─────────────────────────────────────────────
header "Static Website Hosting"

info "Enabling static website hosting..."
az storage blob service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --static-website \
  --index-document "$INDEX_DOC" \
  --404-document "$ERROR_DOC" \
  --output none
success "Static website hosting enabled."

# ── Retrieve Connection String ────────────────────────────────────────────────
CONN_STR=$(az storage account show-connection-string \
  --name "$RESOURCE_GROUP" \
  --resource-group "$RESOURCE_GROUP" \
  --query connectionString -o tsv 2>/dev/null || true)

# Fall back to account-key auth if connection string lookup fails
ACCOUNT_KEY=$(az storage account keys list \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "[0].value" -o tsv)

# ── Upload Website Files ──────────────────────────────────────────────────────
header "Uploading Files"

info "Uploading all files from '$WEBSITE_DIR' to \$web container..."

az storage blob upload-batch \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --source "$WEBSITE_DIR" \
  --destination '$web' \
  --overwrite \
  --content-cache-control "public, max-age=3600" \
  --output table

success "All files uploaded."

# ── Retrieve Static Website URL ───────────────────────────────────────────────
header "Deployment Complete"

STATIC_URL=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "primaryEndpoints.web" -o tsv)

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║         Stratus is LIVE on Azure!                ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Resource Group:   ${RESET}$RESOURCE_GROUP"
echo -e "  ${BOLD}Storage Account:  ${RESET}$STORAGE_ACCOUNT"
echo -e "  ${BOLD}Region:           ${RESET}$LOCATION"
echo -e "  ${BOLD}Live URL:         ${RESET}${CYAN}$STATIC_URL${RESET}"
echo ""
echo -e "  ${YELLOW}To tear down all resources:${RESET}"
echo -e "  ./provision-and-deploy.sh --destroy"
echo ""

# ── Save config for GitHub Actions ───────────────────────────────────────────
CONFIG_FILE="$(dirname "$0")/../.azure-config"
cat > "$CONFIG_FILE" <<EOF
STORAGE_ACCOUNT=$STORAGE_ACCOUNT
RESOURCE_GROUP=$RESOURCE_GROUP
STATIC_URL=$STATIC_URL
EOF
info "Config saved to .azure-config (use values for GitHub Actions secrets)"
