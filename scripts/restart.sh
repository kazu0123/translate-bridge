#!/bin/bash
set -euo pipefail

# Translate Bridge Restart Script (using LaunchAgent)
# This script restarts the Translate Bridge server via LaunchAgent
# Idempotent: safe to run multiple times

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SERVER_BINARY="$PROJECT_DIR/bin/translate-bridge"

echo "=== Translate Bridge Restart ==="

# Check if server binary exists
if [ ! -f "$SERVER_BINARY" ]; then
    echo "✗ Server binary not found at:"
    echo "      $SERVER_BINARY"
    echo "Please run install.sh first:"
    echo "  ./scripts/install.sh"
    exit 1
fi

# Rebuild server binary
echo "Rebuilding server binary..."
cd "$PROJECT_DIR"
if ! go build -o "$SERVER_BINARY" ./cmd/translate-bridge; then
    echo "✗ Failed to rebuild server"
    exit 1
fi
echo "✓ Server binary rebuilt at:"
echo "      $SERVER_BINARY"

# Stop the server via LaunchAgent (for idempotency)
echo "Stopping current server instance..."
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
        echo "✓ Server restarted successfully (port 5050 is listening)"
        exit 0
    fi
    sleep 0.5
done

echo ""
echo "✗ Server failed to start within $STARTUP_TIMEOUT seconds"
echo "Please check logs:"
echo "    ~/Library/Logs/Translate Bridge/"
exit 1
