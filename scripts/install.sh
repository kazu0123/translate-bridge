#!/bin/bash
set -euo pipefail

# Translate Bridge Installation Script
# This script installs the Translate Bridge application on macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$HOME/Library/Application Support/Translate Bridge"
PLIST_FILE="$HOME/Library/LaunchAgents/com.kokubokazuki.translate-bridge.plist"
SERVER_BINARY="$PROJECT_DIR/bin/translate-bridge"

echo "=== Translate Bridge Installation ==="

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"
echo "✓ Created config directory: $CONFIG_DIR"

# Copy example config if it doesn't exist
if [ ! -f "$CONFIG_DIR/config.jsonc" ]; then
    if [ -f "$PROJECT_DIR/config.exmaple.jsonc" ]; then
        # Create Python script to clean JSONC
        python3 - "$PROJECT_DIR/config.exmaple.jsonc" "$CONFIG_DIR/config.jsonc" << 'PYTHON_SCRIPT'
import sys
import re

input_file = sys.argv[1]
output_file = sys.argv[2]

with open(input_file, 'r') as f:
    content = f.read()

# Remove // comments
def remove_double_slash_comments(line):
    result = []
    i = 0
    in_string = False
    escape_next = False
    while i < len(line):
        char = line[i]
        
        if escape_next:
            result.append(char)
            escape_next = False
            i += 1
            continue
        
        if char == '\\':
            result.append(char)
            escape_next = True
            i += 1
            continue
        
        if char == '"':
            in_string = not in_string
            result.append(char)
            i += 1
            continue
        
        if char == '/' and not in_string:
            # Check for // comment
            if i + 1 < len(line) and line[i+1] == '/':
                # Found comment, stop here
                break
        
        result.append(char)
        i += 1
    
    return ''.join(result)

# Process each line
lines = content.split('\n')
cleaned_lines = [remove_double_slash_comments(line) for line in lines]

# Remove /* */ comments
content = '\n'.join(cleaned_lines)
content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)

# Parse and reformat as valid JSON
import json
try:
    data = json.loads(content)
except json.JSONDecodeError as e:
    print(f"Warning: Could not parse JSON: {e}")
    # Try to fix common issues
    content = re.sub(r',\s*}', '}', content)
    content = re.sub(r',\s*\]', ']', content)
    data = json.loads(content)

with open(output_file, 'w') as f:
    json.dump(data, f, indent=2)

PYTHON_SCRIPT
        echo "✓ Copied and cleaned config to $CONFIG_DIR/config.jsonc"
    else
        echo "✗ Example config file not found at $PROJECT_DIR/config.exmaple.jsonc"
        exit 1
    fi
else
    echo "✓ Config file already exists at $CONFIG_DIR/config.jsonc"
fi

# Build the Go binary
echo "=== Building Translate Bridge ==="
cd "$PROJECT_DIR"

if ! command -v go &> /dev/null; then
    echo "✗ Go is not installed. Please install Go 1.23 or later."
    exit 1
fi

# Clean and build
go clean -cache
if ! go build -o "$SERVER_BINARY" ./cmd/translate-bridge; then
    echo "✗ Failed to build Translate Bridge"
    exit 1
fi

echo "✓ Built server binary: $SERVER_BINARY"

# Create LaunchAgent plist file
echo "=== Installing LaunchAgent ==="
PLIST_CONTENT='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kokubokazuki.translate-bridge</string>

    <key>ProgramArguments</key>
    <array>
        <string>'"$SERVER_BINARY"'</string>
    </array>

    <key>WorkingDirectory</key>
    <string>'"$PROJECT_DIR"'</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>Crashed</key>
        <true/>
    </dict>

    <key>StandardOutPath</key>
    <string>'"$HOME/Library/Logs/Translate Bridge/output.log"'</string>

    <key>StandardErrorPath</key>
    <string>'"$HOME/Library/Logs/Translate Bridge/error.log"'</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>'

echo "$PLIST_CONTENT" > "$PLIST_FILE"

echo "✓ Created LaunchAgent: $PLIST_FILE"

# Set permissions
chmod 644 "$PLIST_FILE"
echo "✓ Set proper permissions on LaunchAgent"

# Load the LaunchAgent
if launchctl load "$PLIST_FILE" 2>/dev/null; then
    echo "✓ Loaded LaunchAgent"
else
    # Try alternative method
    if launchctl load "$PLIST_FILE" 2>/dev/null; then
        echo "✓ Loaded LaunchAgent (legacy method)"
    else
        echo "Note: Could not load LaunchAgent automatically."
        echo "You may need to run 'launchctl load $PLIST_FILE' manually"
    fi
fi

# Start the server via LaunchAgent and wait for startup confirmation
echo ""
echo "=== Starting Server ==="
STARTUP_TIMEOUT=30  # seconds

# Stop any existing instances first (for idempotency)
launchctl stop com.kokubokazuki.translate-bridge 2>/dev/null || true
sleep 1

# Start the server via LaunchAgent
launchctl start com.kokubokazuki.translate-bridge

# Wait for server to become available
echo "Waiting for server to start..."
for i in $(seq 1 $((STARTUP_TIMEOUT * 2))); do
    if curl -s http://localhost:5050/health > /dev/null 2>&1; then
        echo "✓ Server started successfully (port 5050 is listening)"
        break
    fi
    sleep 0.5
done

# Check if server is running after timeout
if curl -s http://localhost:5050/health > /dev/null 2>&1; then
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Translate Bridge is now installed and running."
    echo "Configuration file:"
    echo "    $CONFIG_DIR/config.jsonc"
    echo ""
    echo "To restart the server, run:"
    echo "  ./scripts/restart.sh"
    exit 0
else
    echo ""
    echo "=== Installation Complete (Server Not Running) ==="
    echo ""
    echo "Files have been installed, but the server could not be started."
    echo "Please check the following:"
    echo "  - Configuration:"
    echo "      $CONFIG_DIR/config.jsonc"
    echo "  - Logs:"
    echo "      ~/Library/Logs/Translate Bridge/"
    echo ""
    echo "You can try to start it manually with:"
    echo "  launchctl start com.kokubokazuki.translate-bridge"
    exit 1
fi
