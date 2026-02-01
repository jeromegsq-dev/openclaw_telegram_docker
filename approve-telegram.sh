#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Telegram Pairing Approval Script for OpenClaw
# =============================================================================

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="$SCRIPT_DIR/openclaw"
COMPOSE_CMD="podman-compose"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== OpenClaw Telegram Approval ===${NC}"
echo ""

if [[ ! -d "$OPENCLAW_DIR" ]]; then
    echo "ERROR: OpenClaw not installed in $OPENCLAW_DIR"
    exit 1
fi

cd "$OPENCLAW_DIR"

# Check if code is passed as argument
if [[ $# -eq 1 ]]; then
    PAIRING_CODE="$1"
else
    echo -e "${YELLOW}Enter the pairing code (e.g. QUDZHACU):${NC}"
    read -p "> " PAIRING_CODE
fi

echo ""
echo -e "${BLUE}Approving code: $PAIRING_CODE${NC}"
echo ""

# Execute approval command
$COMPOSE_CMD exec openclaw-gateway node dist/index.js pairing approve telegram "$PAIRING_CODE"

echo ""
echo -e "${GREEN}[OK] Pairing approved!${NC}"
echo ""
echo "You can now use your Telegram bot."
echo ""
