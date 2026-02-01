#!/bin/bash

# OpenClaw Telegram Docker - Logs Viewer
# Shows OpenClaw Gateway logs (last 100 lines by default, then follows)

cd openclaw
podman-compose logs --tail=100 -f openclaw-gateway
