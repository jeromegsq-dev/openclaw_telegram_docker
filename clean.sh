#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# OpenClaw Cleanup Script
# =============================================================================
# This script completely cleans the OpenClaw installation:
# - Stops and removes containers
# - Removes Docker volumes
# - Removes cloned directory
# - Removes temporary files on host (if present)
# =============================================================================

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="$SCRIPT_DIR/openclaw"


# Use Podman
CONTAINER_ENGINE="podman"
COMPOSE_CMD="podman-compose"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}  OpenClaw Cleanup${NC}"
    echo -e "${RED}=========================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}==> $1${NC}"
}

print_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_header

echo -e "${YELLOW}WARNING: This will delete:${NC}"
echo "  - OpenClaw containers"
echo "  - Docker volumes (openclaw_config, openclaw_workspace)"
echo "  - Directory $OPENCLAW_DIR"
echo ""
read -p "Are you sure? (type 'yes' to confirm): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# === STOP AND REMOVE CONTAINERS ===
if [[ -d "$OPENCLAW_DIR" ]]; then
    print_step "Stopping and removing containers..."
    cd "$OPENCLAW_DIR"

    if [[ -f "docker-compose.yml" ]]; then
        $COMPOSE_CMD down -v 2>/dev/null || print_warning "Containers already stopped"
        print_ok "Containers stopped and removed"
    else
        print_warning "docker-compose.yml not found"
    fi
else
    print_warning "Directory $OPENCLAW_DIR not found"
fi

# === REMOVE DOCKER VOLUMES ===
echo ""
print_step "Removing Docker volumes..."

if $CONTAINER_ENGINE volume ls | grep -q "openclaw_config"; then
    $CONTAINER_ENGINE volume rm openclaw_config 2>/dev/null || print_warning "Volume openclaw_config already removed"
    print_ok "Volume openclaw_config removed"
else
    print_warning "Volume openclaw_config not found"
fi

if $CONTAINER_ENGINE volume ls | grep -q "openclaw_workspace"; then
    $CONTAINER_ENGINE volume rm openclaw_workspace 2>/dev/null || print_warning "Volume openclaw_workspace already removed"
    print_ok "Volume openclaw_workspace removed"
else
    print_warning "Volume openclaw_workspace not found"
fi

# === REMOVE IMAGE ===
echo ""
print_step "Removing Docker image..."

if $CONTAINER_ENGINE images | grep -q "openclaw.*local"; then
    $CONTAINER_ENGINE rmi localhost/openclaw:local 2>/dev/null || print_warning "Image already removed"
    print_ok "Image openclaw:local removed"
else
    print_warning "Image openclaw:local not found"
fi

# === REMOVE CLONED DIRECTORY ===
echo ""
print_step "Removing cloned directory..."

if [[ -d "$OPENCLAW_DIR" ]]; then
    rm -rf "$OPENCLAW_DIR"
    print_ok "Directory $OPENCLAW_DIR removed"
else
    print_warning "Directory already removed"
fi

# === REMOVE CONFIG DIRECTORY (IF PRESENT) ===
echo ""
print_step "Checking config directory on host..."

# === CLEANUP ORPHANED CONTAINERS ===
echo ""
print_step "Cleaning up orphaned containers and images..."

$CONTAINER_ENGINE container prune -f 2>/dev/null || true
$CONTAINER_ENGINE image prune -f 2>/dev/null || true

print_ok "Cleanup completed"

# === SUMMARY ===
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}   Cleanup completed!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "OpenClaw has been completely removed."
echo ""
echo "To reinstall, run:"
echo "  ./setup-openclaw.sh"
echo ""
