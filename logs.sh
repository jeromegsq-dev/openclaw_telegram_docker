#!/bin/bash

# OpenClaw Telegram Docker - Logs Viewer
# Shows OpenClaw Gateway logs (last 100 lines by default, then follows)
# Usage: ./logs.sh [--tail=N] [--follow] [additional podman-compose options]
# Examples:
#   ./logs.sh                    # Last 100 lines, follow mode
#   ./logs.sh --tail=50          # Last 50 lines, follow mode
#   ./logs.sh --tail=1000        # Last 1000 lines, follow mode
#   ./logs.sh --no-log-prefix    # Without log prefix

cd openclaw

if [ $# -eq 0 ]; then
    # No arguments provided, use defaults
    podman-compose logs --tail=100 -f openclaw-gateway
else
    # User provided arguments, use them instead
    podman-compose logs "$@" openclaw-gateway
fi
