#!/bin/bash
# SOCKS5 Server Stop Script
# Gracefully stops the running SOCKS5 server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"
PID_FILE="$SERVER_DIR/socks5.pid"

echo "========================================"
echo "Stopping SOCKS5 Server"
echo "========================================"

if [ ! -f "$PID_FILE" ]; then
    echo "WARNING: PID file not found: $PID_FILE"
    echo "Attempting to find running socks5_server process..."
    
    PID=$(pgrep -f "socks5_server.py" 2>/dev/null || true)
    if [ -z "$PID" ]; then
        echo "No running server found"
        exit 0
    fi
else
    PID=$(cat "$PID_FILE")
    echo "Found PID: $PID"
fi

# Check if process exists
if ! kill -0 "$PID" 2>/dev/null; then
    echo "Process $PID is not running"
    rm -f "$PID_FILE"
    exit 0
fi

echo "Sending SIGTERM to process $PID..."
kill -TERM "$PID" || true

# Wait for graceful shutdown (max 10 seconds)
for i in {1..10}; do
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "✓ Server stopped gracefully"
        rm -f "$PID_FILE"
        exit 0
    fi
    echo "Waiting... ($i/10)"
    sleep 1
done

# Force kill if still running
echo "Process didn't stop gracefully. Sending SIGKILL..."
kill -KILL "$PID" || true
sleep 1

if ! kill -0 "$PID" 2>/dev/null; then
    echo "✓ Server stopped forcefully"
    rm -f "$PID_FILE"
else
    echo "ERROR: Failed to stop server"
    exit 1
fi
