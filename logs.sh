#!/bin/bash

# OpenClaw Telegram Docker - Logs Viewer
# Shows OpenClaw Gateway logs (last 100 lines by default, then follows)
# Usage: ./logs.sh [--tail=N] [--follow] [additional podman-compose options]
# Examples:
#   ./logs.sh                    # Last 100 lines, follow mode
#   ./logs.sh --tail=50          # Last 50 lines, follow mode
#   ./logs.sh --tail=1000        # Last 1000 lines, follow mode
#   ./logs.sh --tail=10 --follow # Last 10 lines, follow mode

cd openclaw
podman-compose logs --tail=100 -f "$@" openclaw-gateway
