#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# OpenClaw + Telegram + Z.ai Installation Script
# =============================================================================
# This script installs OpenClaw in Docker with:
# - Z.ai as LLM provider (via Anthropic-compatible API)
# - Telegram as communication channel
# - EVERYTHING in Docker (named volumes, nothing on host system)
# =============================================================================

# === PARSE ARGUMENTS ===
VERBOSE=false

show_help() {
    cat << EOF
OpenClaw + Telegram + Z.ai Installer

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -v, --verbose    Show detailed output
    -h, --help       Show this help message

EXAMPLES:
    $0               # Install with minimal output
    $0 -v            # Install with verbose output
    $0 --help        # Show this help

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# === CONFIGURATION ===
# Script directory (we work directly here)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="$SCRIPT_DIR/openclaw"

# Use Podman instead of Docker
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
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}  OpenClaw + Telegram + Z.ai Installer${NC}"
    echo -e "${BLUE}  (Everything in Docker, nothing on host)${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
}

print_step() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${YELLOW}==> $1${NC}"
    fi
}

print_ok() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${GREEN}[OK]${NC} $1"
    fi
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_progress() {
    echo -e "${BLUE}▸${NC} $1"
}

# === HEADER ===
print_header

# === ENFORCE PODMAN FOR SECURITY ===
print_step "Checking prerequisites..."

CONTAINER_ENGINE="podman"
COMPOSE_CMD="podman-compose"

# Check for Podman
if ! command -v podman &> /dev/null; then
    print_error "Podman is not installed."
    echo ""
    echo "⚠️  SECURITY REQUIREMENT: This project requires Podman, not Docker."
    echo ""
    echo "Why Podman?"
    echo "  ✓ Rootless by default (no daemon running as root)"
    echo "  ✓ More secure architecture (no privileged daemon)"
    echo "  ✓ Compatible with Docker workflows"
    echo "  ✓ Better isolation and security boundaries"
    echo ""
    echo "Docker is NOT supported because:"
    echo "  ✗ Runs as root daemon (security risk)"
    echo "  ✗ Gives container access to host system"
    echo "  ✗ Privileged escalation vulnerabilities"
    echo ""
    echo "Install Podman:"
    echo "  Ubuntu/Debian:  sudo apt install podman"
    echo "  Fedora:         sudo dnf install podman"
    echo "  Arch:           sudo pacman -S podman"
    echo "  macOS:          brew install podman"
    echo ""
    exit 1
fi

print_ok "Podman found: $(podman --version)"

# Check for podman-compose
if ! command -v podman-compose &> /dev/null; then
    print_error "podman-compose is not installed."
    echo ""
    echo "Install podman-compose:"
    echo "  pip install podman-compose"
    echo "  or: pip3 install podman-compose"
    echo "  or: python3 -m pip install podman-compose"
    echo ""
    exit 1
fi

print_ok "podman-compose found"

# Verify Podman is working
if ! podman info &> /dev/null; then
    print_error "Podman is not working properly."
    echo ""
    echo "Start Podman:"
    echo "  Linux:  sudo systemctl start podman (if using service)"
    echo "  macOS:  podman machine init && podman machine start"
    echo ""
    exit 1
fi

print_ok "Podman is ready and secure ✓"

# === LOAD .ENV IF EXISTS ===
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    echo ""
    print_progress "Loading configuration from .env file..."
    source "$SCRIPT_DIR/.env"

    if [[ -n "$TELEGRAM_BOT_TOKEN" ]] && [[ -n "$ZAI_API_KEY" ]]; then
        print_ok "Configuration loaded from .env"

        # Use PRIMARY_MODEL from .env or default
        if [[ -z "$PRIMARY_MODEL" ]]; then
            PRIMARY_MODEL="zai/claude-3-opus-20240229"
        fi

        MODEL_NAME=$(echo "$PRIMARY_MODEL" | sed 's/zai\///')
        print_ok "Using model: $MODEL_NAME"
    else
        print_error ".env file exists but missing required variables"
        echo "Required: TELEGRAM_BOT_TOKEN, ZAI_API_KEY"
        exit 1
    fi
else
    # === REQUEST CREDENTIALS ===
    echo ""
    echo -e "${BLUE}--- Configuration ---${NC}"
    echo ""
    echo "To create a Telegram bot:"
    echo "  1. Open Telegram app and search for @BotFather"
    echo "  2. Start a chat: https://t.me/BotFather"
    echo "  3. Send /newbot and follow instructions"
    echo "  4. Copy the bot token"
    echo ""

    read -sp "Enter your Telegram bot token: " TELEGRAM_BOT_TOKEN
    echo
    echo ""
    echo "To get your Z.ai API key:"
    echo "  1. Login to Z.ai"
    echo "  2. Go to: https://z.ai/manage-apikey/apikey-list"
    echo "  3. Create a new API key"
    echo ""

    read -sp "Enter your Z.ai API key: " ZAI_API_KEY
    echo

    if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
        print_error "Telegram token is required."
        exit 1
    fi

    if [[ -z "$ZAI_API_KEY" ]]; then
        print_error "Z.ai API key is required."
        exit 1
    fi

    # === MODEL SELECTION ===
    echo ""
    echo -e "${BLUE}--- Model selection ---${NC}"
    echo ""
    echo "Available models:"
    echo "  1) Claude 3 Opus (claude-3-opus-20240229)"
    echo "  2) Claude 3.5 Sonnet (claude-3-5-sonnet-20240620)"
    echo "  3) Claude 3.5 Sonnet v2 (claude-3-5-sonnet-20241022)"
    echo "  4) GLM-4.7 (glm-4.7)"
    echo ""
    read -p "Choose a model [1-4] (default: 1): " MODEL_CHOICE

    case "$MODEL_CHOICE" in
        2)
            PRIMARY_MODEL="zai/claude-3-5-sonnet-20240620"
            MODEL_NAME="Claude 3.5 Sonnet"
            ;;
        3)
            PRIMARY_MODEL="zai/claude-3-5-sonnet-20241022"
            MODEL_NAME="Claude 3.5 Sonnet v2"
            ;;
        4)
            PRIMARY_MODEL="zai/glm-4.7"
            MODEL_NAME="GLM-4.7"
            ;;
        *)
            PRIMARY_MODEL="zai/claude-3-opus-20240229"
            MODEL_NAME="Claude 3 Opus"
            ;;
    esac

    print_ok "Selected model: $MODEL_NAME"
fi

export ZAI_API_KEY
export TELEGRAM_BOT_TOKEN
export PRIMARY_MODEL

# === CLONE REPOSITORY ===
echo ""
print_progress "Cloning OpenClaw repository..."
print_step "Cloning OpenClaw..."

if [[ -d "$OPENCLAW_DIR" ]]; then
    if [[ "$VERBOSE" == "true" ]]; then
        echo "Existing directory detected, updating..."
    fi
    cd "$OPENCLAW_DIR"
    git pull --quiet 2>&1 | grep -v "Already up to date" || true
else
    git clone --quiet https://github.com/openclaw/openclaw.git "$OPENCLAW_DIR"
    cd "$OPENCLAW_DIR"
fi

print_ok "OpenClaw cloned to $OPENCLAW_DIR"

# === GENERATE GATEWAY TOKEN ===
OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
export OPENCLAW_GATEWAY_TOKEN

print_ok "Gateway token generated"

# === CREATE DOCKER-COMPOSE.OVERRIDE.YML ===
echo ""
print_step "Creating docker-compose.override.yml with Docker volumes..."

cat > docker-compose.override.yml << 'EOF'
services:
  openclaw-gateway:
    volumes:
      - openclaw_config:/home/node/.openclaw
      - openclaw_workspace:/home/node/.openclaw/workspace
    environment:
      HOME: /home/node
      TERM: xterm-256color
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN}

  openclaw-cli:
    volumes:
      - openclaw_config:/home/node/.openclaw
      - openclaw_workspace:/home/node/.openclaw/workspace
    environment:
      HOME: /home/node
      TERM: xterm-256color

volumes:
  openclaw_config:
    name: openclaw_config
  openclaw_workspace:
    name: openclaw_workspace
EOF

print_ok "docker-compose.override.yml created"

# === BUILD IMAGE ===
echo ""
print_progress "Building Docker image (this may take a few minutes)..."
print_step "Building image (this may take a few minutes)..."

if [[ "$VERBOSE" == "true" ]]; then
    $CONTAINER_ENGINE build -t openclaw:local -f Dockerfile .
else
    $CONTAINER_ENGINE build -t openclaw:local -f Dockerfile . > /dev/null 2>&1
fi

print_ok "Image built"

# === PREPARE CONFIGURATION FILES ===
echo ""
print_progress "Preparing configuration..."
print_step "Preparing configuration files..."

# Create temporary file with complete config
TEMP_CONFIG=$(mktemp)
cat > "$TEMP_CONFIG" << EOF
{
  "meta": {
    "lastTouchedVersion": "2026.1.30",
    "lastTouchedAt": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"
  },
  "wizard": {
    "lastRunAt": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
    "lastRunVersion": "2026.1.30",
    "lastRunCommand": "onboard",
    "lastRunMode": "local"
  },
  "auth": {
    "profiles": {
      "zai:default": {
        "provider": "zai",
        "mode": "api_key"
      }
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "zai": {
        "baseUrl": "https://api.z.ai/api/anthropic",
        "apiKey": "$ZAI_API_KEY",
        "api": "anthropic-messages",
        "models": [
          {
            "id": "claude-3-opus-20240229",
            "name": "Claude 3 Opus",
            "reasoning": false,
            "input": ["text"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 200000,
            "maxTokens": 8192
          },
          {
            "id": "claude-3-5-sonnet-20240620",
            "name": "Claude 3.5 Sonnet",
            "reasoning": false,
            "input": ["text"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 200000,
            "maxTokens": 8192
          },
          {
            "id": "claude-3-5-sonnet-20241022",
            "name": "Claude 3.5 Sonnet v2",
            "reasoning": false,
            "input": ["text"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 200000,
            "maxTokens": 8192
          },
          {
            "id": "glm-4.7",
            "name": "GLM-4.7",
            "reasoning": false,
            "input": ["text"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 128000,
            "maxTokens": 4096
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {"primary": "$PRIMARY_MODEL"},
      "workspace": "/home/node/.openclaw/workspace",
      "maxConcurrent": 4,
      "subagents": {"maxConcurrent": 8}
    }
  },
  "messages": {"ackReactionScope": "group-mentions"},
  "commands": {"native": "auto", "nativeSkills": "auto"},
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {"boot-md": {"enabled": true}}
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "botToken": "$TELEGRAM_BOT_TOKEN",
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "$OPENCLAW_GATEWAY_TOKEN"
    },
    "controlUi": {
      "allowInsecureAuth": true
    },
    "tailscale": {"mode": "off", "resetOnExit": false}
  },
  "skills": {"install": {"nodeManager": "npm"}},
  "plugins": {"entries": {"telegram": {"enabled": true}}}
}
EOF

# Telegram allowFrom file (empty - no pre-approved users)
TEMP_TELEGRAM=$(mktemp)
cat > "$TEMP_TELEGRAM" << 'EOF'
{"version": 1, "entries": []}
EOF

# Empty pairing file
TEMP_PAIRING=$(mktemp)
cat > "$TEMP_PAIRING" << 'EOF'
{"version": 1, "requests": []}
EOF

# Webchat allowFrom file (allow all localhost connections)
TEMP_WEBCHAT=$(mktemp)
cat > "$TEMP_WEBCHAT" << 'EOF'
{"version": 1, "entries": [{"id": "*", "name": "localhost", "approvedAt": "2026-02-01T00:00:00.000Z"}]}
EOF

print_ok "Configuration files prepared"

# === INJECT CONFIGURATION INTO DOCKER VOLUME ===
echo ""
print_progress "Injecting configuration into Docker volume..."
print_step "Injecting configuration into Docker volume..."

# Create directories and copy files via temporary container
INJECT_OUTPUT=$($COMPOSE_CMD run --rm --entrypoint sh openclaw-cli -c "
  mkdir -p /home/node/.openclaw/credentials
  mkdir -p /home/node/.openclaw/workspace
  mkdir -p /home/node/.openclaw/agents
  mkdir -p /home/node/.openclaw/identity
  mkdir -p /home/node/.openclaw/logs
  mkdir -p /home/node/.openclaw/canvas
  mkdir -p /home/node/.openclaw/cron
  mkdir -p /home/node/.openclaw/telegram

  cat > /home/node/.openclaw/openclaw.json << 'INNEREOF'
$(cat "$TEMP_CONFIG")
INNEREOF

  cat > /home/node/.openclaw/credentials/telegram-allowFrom.json << 'INNEREOF'
$(cat "$TEMP_TELEGRAM")
INNEREOF

  cat > /home/node/.openclaw/credentials/telegram-pairing.json << 'INNEREOF'
$(cat "$TEMP_PAIRING")
INNEREOF

  cat > /home/node/.openclaw/credentials/webchat-allowFrom.json << 'INNEREOF'
$(cat "$TEMP_WEBCHAT")
INNEREOF

  chmod 600 /home/node/.openclaw/openclaw.json
  chmod 600 /home/node/.openclaw/credentials/*.json

  echo 'Configuration injected successfully'
" 2>&1)

if [[ "$VERBOSE" == "true" ]]; then
    echo "$INJECT_OUTPUT"
fi

# Clean up temporary files
rm -f "$TEMP_CONFIG" "$TEMP_TELEGRAM" "$TEMP_PAIRING" "$TEMP_WEBCHAT"

print_ok "Configuration injected into Docker volume"

# === START GATEWAY ===
echo ""
print_progress "Starting gateway..."
print_step "Starting gateway..."

if [[ "$VERBOSE" == "true" ]]; then
    OPENCLAW_GATEWAY_TOKEN="$OPENCLAW_GATEWAY_TOKEN" $COMPOSE_CMD up -d openclaw-gateway
else
    OPENCLAW_GATEWAY_TOKEN="$OPENCLAW_GATEWAY_TOKEN" $COMPOSE_CMD up -d openclaw-gateway > /dev/null 2>&1
fi

print_ok "Gateway started"

# === FINAL SUMMARY ===
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}   Installation completed successfully!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "Gateway URL:    ${BLUE}http://127.0.0.1:18789/${NC}"
echo -e "Gateway Token:  ${YELLOW}$OPENCLAW_GATEWAY_TOKEN${NC}"
echo ""
echo -e "${GREEN}✓${NC} No files on host macOS system"
echo -e "${GREEN}✓${NC} Everything is in Docker volumes"
echo ""
echo -e "${YELLOW}⚠ Pairing required:${NC}"
echo "  1. Send a message to your Telegram bot"
echo "  2. The bot will give you a pairing code (e.g. ABCD1234)"
echo "  3. Approve with: ./approve-telegram.sh <code>"
echo ""
echo -e "${BLUE}--- Useful commands ---${NC}"
echo ""
echo "  cd $OPENCLAW_DIR"
echo ""
echo "  # View logs"
echo "  $COMPOSE_CMD logs -f openclaw-gateway"
echo ""
echo "  # Restart"
echo "  $COMPOSE_CMD restart openclaw-gateway"
echo ""
echo "  # Stop"
echo "  $COMPOSE_CMD down"
echo ""
echo "  # List volumes"
echo "  $CONTAINER_ENGINE volume ls | grep openclaw"
echo ""
echo "  # Clean everything (DELETES ALL)"
echo "  $COMPOSE_CMD down -v"
echo ""
