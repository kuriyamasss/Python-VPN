#!/bin/bash
# SOCKS5 Server Start Script
# Usage: ./start.sh [--daemon] [--config /path/to/config.py]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"
PYTHON_CMD="${PYTHON_CMD:-python3}"
DAEMON_MODE=false
CONFIG_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --daemon)
            DAEMON_MODE=true
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--daemon] [--config /path/to/config.py] [--help]"
            echo ""
            echo "Options:"
            echo "  --daemon         Run server in background (daemon mode)"
            echo "  --config FILE    Use custom config file"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check Python availability
if ! command -v "$PYTHON_CMD" &> /dev/null; then
    echo "ERROR: Python 3 is not installed or not in PATH"
    echo "Please install Python 3.7 or later"
    exit 1
fi

# Create logs directory if it doesn't exist
mkdir -p "$SERVER_DIR/logs"

echo "========================================"
echo "SOCKS5 Server"
echo "========================================"
echo "Server directory: $SERVER_DIR"
echo "Python: $($PYTHON_CMD --version)"
echo ""

# Set Python path
export PYTHONPATH="$SERVER_DIR:$PYTHONPATH"

# Run server
if [ "$DAEMON_MODE" = true ]; then
    echo "Starting SOCKS5 server in daemon mode..."
    nohup "$PYTHON_CMD" "$SERVER_DIR/socks5_server.py" > "$SERVER_DIR/logs/startup.log" 2>&1 &
    PID=$!
    echo "✓ Server started with PID: $PID"
    echo "$PID" > "$SERVER_DIR/socks5.pid"
else
    echo "Starting SOCKS5 server in foreground mode (Press Ctrl+C to stop)..."
    echo ""
    "$PYTHON_CMD" "$SERVER_DIR/socks5_server.py"
fi
