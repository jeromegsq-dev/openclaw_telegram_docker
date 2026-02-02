# OpenClaw Telegram Docker Bot

Easy setup for OpenClaw with Telegram integration using Docker/Podman, configured with Z.ai as LLM provider.

## Features

- 🐳 **Full Docker setup** - Everything runs in containers, nothing on your host
- 🤖 **Telegram bot** - Connect your Telegram account
- 🧠 **Z.ai integration** - Use Z.ai as LLM provider (Claude, GLM models)
- 🔧 **Easy configuration** - Simple `.env` file or interactive setup
- 🌐 **Web interface** - Control UI accessible via browser

## Prerequisites

- **Podman** (required, Docker is NOT supported)
- **podman-compose**
- **Telegram Bot Token** - Get it from [@BotFather](https://t.me/BotFather)
- **Z.ai API Key** - Get it from [Z.ai](https://z.ai/manage-apikey/apikey-list)

### Why Podman only?

⚠️ **Docker is intentionally NOT supported** for security reasons:

| Feature | Podman ✅ | Docker ❌ |
|---------|----------|-----------|
| Rootless by default | Yes | No |
| Daemon runs as | User | Root |
| Security model | Secure | Privileged |
| CVE vulnerabilities | Fewer | More |

**Podman benefits:**
- ✓ Rootless architecture (no root daemon)
- ✓ More secure isolation
- ✓ Drop-in replacement for Docker
- ✓ Better security boundaries

**Install Podman:**
```bash
# Ubuntu/Debian
sudo apt install podman

# Fedora
sudo dnf install podman

# macOS
brew install podman

# Install podman-compose
pip install podman-compose
```

## Quick Start

### 1. Clone this repository

```bash
git clone <your-repo-url>
cd openclaw_telegram_docker_bot
```

### 2. Configure (Option A: .env file)

```bash
cp .env.example .env
# Edit .env with your credentials
```

### 2. Configure (Option B: Interactive)

Just run the setup script without a `.env` file, it will ask for credentials.

### 3. Install

```bash
./setup-openclaw.sh
```

For verbose output:
```bash
./setup-openclaw.sh -v
```

### 4. Access the Web Interface

```bash
./get-dashboard-url.sh
```

Copy the URL and open it in your browser.

### 5. Approve Telegram Pairing

1. Send a message to your Telegram bot
2. Copy the pairing code from the bot's response
3. Run:
   ```bash
   ./approve-telegram.sh <PAIRING_CODE>
   ```

## Available Scripts

- `./setup-openclaw.sh` - Install and configure OpenClaw
- `./setup-openclaw.sh -v` - Install with verbose output
- `./setup-openclaw.sh --help` - Show help
- `./get-token.sh` - Get the web interface URL with token
- `./approve-telegram.sh <code>` - Approve Telegram pairing
- `./clean.sh` - Clean everything (removes containers, volumes, images)

## Configuration

### .env file

```env
# Telegram Bot Token (from @BotFather)
TELEGRAM_BOT_TOKEN=your_telegram_token

# Z.ai API Key
ZAI_API_KEY=your_zai_api_key

# Primary Model (optional)
PRIMARY_MODEL=zai/claude-3-opus-20240229
```

### Available Models

- `zai/claude-3-opus-20240229` (default)
- `zai/claude-3-5-sonnet-20240620`
- `zai/claude-3-5-sonnet-20241022`
- `zai/glm-4.7`

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────┐
│   Telegram Bot  │────▶│  OpenClaw Docker │────▶│   Z.ai API  │
│                 │     │   (Gateway)      │     │             │
└─────────────────┘     └──────────────────┘     └─────────────┘
```

## Troubleshooting

### Check logs

```bash
cd openclaw
podman-compose logs -f openclaw-gateway
```

### Restart gateway

```bash
cd openclaw
podman-compose restart openclaw-gateway
```

### Clean installation

```bash
./clean.sh
./setup-openclaw.sh
```

## Security Notes

⚠️ **Never commit your `.env` file to git** - It contains sensitive credentials

The `.gitignore` file is configured to exclude:
- `.env` file
- `openclaw/` directory
- `.claude/` directory

## Links

- [OpenClaw Documentation](https://docs.openclaw.ai/)
- [Z.ai API Keys](https://z.ai/manage-apikey/apikey-list)
- [Telegram BotFather](https://t.me/BotFather)

## License

MIT
