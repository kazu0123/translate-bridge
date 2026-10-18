#!/bin/bash
set -euo pipefail

# Translate Bridge Stop Script (using LaunchAgent)
# This script stops the Translate Bridge server via LaunchAgent
# Idempotent: safe to run multiple times

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Translate Bridge Stop ==="

# Check if LaunchAgent is loaded
PLIST_FILE="$HOME/Library/LaunchAgents/com.kokubokazuki.translate-bridge.plist"
if [ ! -f "$PLIST_FILE" ]; then
    echo "✗ LaunchAgent not found at $PLIST_FILE"
    exit 1
fi

# Stop the server via LaunchAgent
echo "Stopping Translate Bridge server..."
launchctl stop com.kokubokazuki.translate-bridge

# Wait for process to exit
sleep 1

# Verify it's stopped
if curl -s http://localhost:5050/health > /dev/null 2>&1; then
    echo "✗ Server is still running"
    exit 1
else
    echo "✓ Server stopped successfully"
fi
