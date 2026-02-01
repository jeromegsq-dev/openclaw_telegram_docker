#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Get OpenClaw Gateway Token
# =============================================================================

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="$SCRIPT_DIR/openclaw"
COMPOSE_CMD="podman-compose"

# Colors
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== OpenClaw Gateway Token ===${NC}"
echo ""

if [[ ! -d "$OPENCLAW_DIR" ]]; then
    echo "ERROR: OpenClaw not installed in $OPENCLAW_DIR"
    exit 1
fi

cd "$OPENCLAW_DIR"

# Extract token from Docker volume
TOKEN=$($COMPOSE_CMD exec openclaw-gateway sh -c "cat /home/node/.openclaw/openclaw.json" 2>/dev/null | grep '"token":' | grep -v '"mode"' | head -1 | sed 's/.*"token": "\([^"]*\)".*/\1/' | tr -d ' \n\r')

if [[ -z "$TOKEN" ]]; then
    echo "ERROR: Could not retrieve gateway token"
    exit 1
fi

echo -e "${YELLOW}Gateway URL:${NC}"
echo "http://127.0.0.1:18789/?token=$TOKEN"
echo ""
