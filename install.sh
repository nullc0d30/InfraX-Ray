#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# InfraX-Ray Installer
# Safe, informative, and robust.

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[*] InfraX-Ray Installer Initialized...${NC}"

# 1. Dependency Check Function
function check_and_install() {
    PKG=$1
    if dpkg -l | grep -q "^ii  $PKG "; then
        echo -e "${GREEN}[+] $PKG is installed.${NC}"
    else
        echo -e "${YELLOW}[!] Installing $PKG...${NC}"
        sudo apt-get install -y -qq $PKG
    fi
}

# 2. OS Detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    echo -e "${GREEN}[+] Detected OS: $OS${NC}"
else
    echo -e "${RED}[!] Could not detect OS. Proceeding with caution.${NC}"
fi

# 3. System Tools
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}[!] Not running as root. System package installation might fail.${NC}"
   echo -e "${YELLOW}[!] Please ensure: git, curl, wget, jq, python3, libpcap-dev are installed.${NC}"
else
   echo -e "${BLUE}[*] Updating package lists...${NC}"
   sudo apt-get update -qq
   
   DEPS="git curl wget jq python3 python3-pip libpcap-dev zip"
   for dep in $DEPS; do
       check_and_install $dep
   done
fi

# 4. Go Environment
if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}[!] Go is not installed. It is required for core tools.${NC}"
    echo -e "${BLUE}[*] Attempting to install Golang...${NC}"
    # Minimal attempt - user usually should handle this for specific versions
    sudo apt-get install -y golang-go
fi

# 5. External Tools
RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_SCRIPT="$RUN_DIR/tools/install_tools.sh"

if [ -f "$TOOLS_SCRIPT" ]; then
    chmod +x "$TOOLS_SCRIPT"
    "$TOOLS_SCRIPT"
else
    echo -e "${RED}[!] Error: tools/install_tools.sh not found!${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Installation Complete.${NC}"
echo -e "${BLUE}[*] You can now run: ./infraxray.sh scan target.com${NC}"
