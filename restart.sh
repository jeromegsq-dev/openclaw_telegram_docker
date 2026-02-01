#!/bin/bash

# OpenClaw Telegram Docker - Gateway Restarter
# Restarts the OpenClaw Gateway container

cd openclaw
podman-compose restart openclaw-gateway

echo "✅ OpenClaw Gateway restarted"
echo ""
echo "📊 Current status:"
podman-compose ps openclaw-gateway
