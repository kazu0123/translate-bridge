#!/bin/bash
set -euo pipefail

# Translate Bridge Start Script (using LaunchAgent)
# This script starts the Translate Bridge server via LaunchAgent
# Idempotent: safe to run multiple times

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SERVER_BINARY="$PROJECT_DIR/bin/translate-bridge"
PLIST_FILE="$HOME/Library/LaunchAgents/com.kokubokazuki.translate-bridge.plist"
CONFIG_FILE="$HOME/Library/Application Support/Translate Bridge/config.jsonc"

echo "=== Translate Bridge Start ==="

# Check if LaunchAgent plist exists
if [ ! -f "$PLIST_FILE" ]; then
    echo "✗ LaunchAgent not found at:"
    echo "      $PLIST_FILE"
    echo "Please run install.sh first:"
    echo "  ./scripts/install.sh"
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "✗ Configuration file not found at:"
    echo "      $CONFIG_FILE"
    echo "Please run install.sh first:"
    echo "  ./scripts/install.sh"
    exit 1
fi

# Stop any existing instances first (for idempotency)
echo "Checking for existing server..."
launchctl stop com.kokubokazuki.translate-bridge 2>/dev/null || true
sleep 1

# Start the server via LaunchAgent
echo "Starting Translate Bridge server..."
launchctl start com.kokubokazuki.translate-bridge

# Wait for server to become available
echo "Waiting for server to start..."
STARTUP_TIMEOUT=30
for i in $(seq 1 $((STARTUP_TIMEOUT * 2))); do
    if curl -s http://localhost:5050/health > /dev/null 2>&1; then
        echo "✓ Server started successfully (port 5050 is listening)"
        exit 0
    fi
    sleep 0.5
done

echo ""
echo "✗ Server failed to start within $STARTUP_TIMEOUT seconds"
echo "Please check:"
echo "  - Configuration:"
echo "      $CONFIG_FILE"
echo "  - Logs:"
echo "      ~/Library/Logs/Translate Bridge/"
exit 1
