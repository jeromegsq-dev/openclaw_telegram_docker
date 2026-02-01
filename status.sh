#!/bin/bash

# OpenClaw Telegram Docker - Status Checker
# Shows container status

cd openclaw
podman-compose ps

# Additional info
echo ""
echo "📊 Quick health check:"
podman-compose ps | grep -q "Up" && echo "✅ OpenClaw Gateway is running" || echo "❌ OpenClaw Gateway is not running"
