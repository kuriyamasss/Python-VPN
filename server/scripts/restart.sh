#!/bin/bash
# SOCKS5 Server Restart Script
# Stops and starts the SOCKS5 server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "Restarting SOCKS5 Server"
echo "========================================"
echo ""

# Stop server
echo "[1/2] Stopping server..."
"$SCRIPT_DIR/stop.sh" || true
sleep 2

# Start server
echo ""
echo "[2/2] Starting server..."
"$SCRIPT_DIR/start.sh" --daemon

echo ""
echo "✓ Server restart complete"
