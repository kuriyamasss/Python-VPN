#!/bin/bash
# Status script to check if SOCKS5 server is running

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"
PID_FILE="$SERVER_DIR/socks5.pid"

echo "========================================"
echo "SOCKS5 Server Status"
echo "========================================"

if [ ! -f "$PID_FILE" ]; then
    echo "Status: STOPPED (no PID file)"
    exit 1
fi

PID=$(cat "$PID_FILE")
echo "PID from file: $PID"

if kill -0 "$PID" 2>/dev/null; then
    echo "Status: ✓ RUNNING (PID $PID)"
    
    # Show process info
    if command -v ps &> /dev/null; then
        echo ""
        echo "Process info:"
        ps -p "$PID" -o pid,ppid,cmd,etime 2>/dev/null || true
    fi
    exit 0
else
    echo "Status: ✗ STOPPED (PID $PID not found)"
    exit 1
fi
