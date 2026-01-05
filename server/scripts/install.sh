#!/bin/bash
# SOCKS5 Server Installation Script for Ubuntu/Debian
# Usage: sudo ./install.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================"
echo "SOCKS5 Server Installation"
echo "========================================${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}ERROR: This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Installing Python 3...${NC}"
    apt-get update
    apt-get install -y python3 python3-pip
fi

# Create service user
if ! id -u socks5 > /dev/null 2>&1; then
    echo -e "${YELLOW}Creating socks5 service user...${NC}"
    useradd -r -s /bin/false -d /var/lib/socks5 socks5
fi

# Installation directory
INSTALL_DIR="/opt/simplevpn"
echo -e "${YELLOW}Installation directory: $INSTALL_DIR${NC}"

# Create installation directory
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    echo -e "${GREEN}✓ Created $INSTALL_DIR${NC}"
fi

# Copy server files
echo -e "${YELLOW}Copying server files...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_PARENT="$(dirname "$SCRIPT_DIR")"

cp -r "$SERVER_PARENT"/* "$INSTALL_DIR/server/"
chown -R socks5:socks5 "$INSTALL_DIR/server"
chmod 755 "$INSTALL_DIR/server/scripts"/*.sh
echo -e "${GREEN}✓ Files copied${NC}"

# Install systemd service
echo -e "${YELLOW}Installing systemd service...${NC}"
cp "$INSTALL_DIR/server/scripts/socks5.service" /etc/systemd/system/
systemctl daemon-reload
echo -e "${GREEN}✓ Systemd service installed${NC}"

# Create log directory
echo -e "${YELLOW}Setting up logs directory...${NC}"
mkdir -p "$INSTALL_DIR/server/logs"
chown socks5:socks5 "$INSTALL_DIR/server/logs"
chmod 755 "$INSTALL_DIR/server/logs"
echo -e "${GREEN}✓ Logs directory created${NC}"

# Show next steps
echo ""
echo -e "${GREEN}========================================"
echo "Installation Complete!"
echo "========================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure the server (edit config):"
echo "   sudo nano $INSTALL_DIR/server/config.py"
echo ""
echo "2. Start the service:"
echo "   sudo systemctl start socks5"
echo ""
echo "3. Enable auto-start on boot:"
echo "   sudo systemctl enable socks5"
echo ""
echo "4. Check service status:"
echo "   sudo systemctl status socks5"
echo ""
echo "5. View logs:"
echo "   sudo journalctl -u socks5 -f"
echo ""
echo "Useful commands:"
echo "   systemctl start socks5      - Start the service"
echo "   systemctl stop socks5       - Stop the service"
echo "   systemctl restart socks5    - Restart the service"
echo "   systemctl enable socks5     - Enable auto-start"
echo "   systemctl disable socks5    - Disable auto-start"
echo "   journalctl -u socks5 -f     - Follow logs in real-time"
echo ""
