#!/bin/bash

# OpenClaw Telegram Docker - Logs Viewer
# Shows OpenClaw Gateway logs

cd openclaw
podman-compose logs -f openclaw-gateway
