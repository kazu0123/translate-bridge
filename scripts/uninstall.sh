#!/bin/bash
set -euo pipefail

# Translate Bridge Uninstall Script (using LaunchAgent)
# This script uninstalls the Translate Bridge application
# Config and logs are preserved by default

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SERVER_BINARY="$PROJECT_DIR/bin/translate-bridge"
CONFIG_DIR="$HOME/Library/Application Support/Translate Bridge"
PLIST_FILE="$HOME/Library/LaunchAgents/com.kokubokazuki.translate-bridge.plist"
LOG_DIR="$HOME/Library/Logs/Translate Bridge"

echo "=== Translate Bridge Uninstall ==="

# Stop the server via LaunchAgent
echo "Stopping server..."
launchctl stop com.kokubokazuki.translate-bridge 2>/dev/null || true
sleep 1

# Unload LaunchAgent if loaded
if [ -f "$PLIST_FILE" ]; then
    echo "Unloading LaunchAgent..."
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
fi

# Remove server binary if exists
if [ -f "$SERVER_BINARY" ]; then
    echo "Removing server binary..."
    rm -f "$SERVER_BINARY"
fi

# Show what was removed and what to manually delete
echo ""
echo "=== Uninstall Complete ==="
echo ""
echo "The following files have been removed:"
echo "  - LaunchAgent:"
echo "      $PLIST_FILE"
if [ -f "$SERVER_BINARY" ]; then
    echo "  - Server binary:"
echo "      $SERVER_BINARY"
else
    echo "  - Server binary: (already removed)"
fi

cat << 'EOF'

For a complete uninstall, you may also want to remove the following files:

  - Configuration file:
      ~/Library/Application Support/Translate Bridge/config.jsonc
  - Log files:
      ~/Library/Logs/Translate Bridge/

To remove these files manually, run:

  rm -rf "~/Library/Application Support/Translate Bridge"
  rm -rf "~/Library/Logs/Translate Bridge"

EOF
