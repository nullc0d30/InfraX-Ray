#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# InfraX-Ray Tool Installer
# Installs stable, pinned versions where possible.

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

GO_BIN_PATH="$HOME/go/bin"
export PATH=$PATH:$GO_BIN_PATH

echo -e "${BLUE}[*] Verifying External Tools...${NC}"

function install_go_tool() {
    TOOL_NAME=$1
    REPO_URL=$2
    if command -v $TOOL_NAME &> /dev/null; then
        echo -e "${GREEN}[+] $TOOL_NAME is ready.${NC}"
    else
        echo -e "${YELLOW}[^] Installing $TOOL_NAME from $REPO_URL...${NC}"
        go install -v $REPO_URL@latest
    fi
}

# ProjectDiscovery Suite (Stable)
install_go_tool "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
install_go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx"
install_go_tool "naabu" "github.com/projectdiscovery/naabu/v2/cmd/naabu"
install_go_tool "nuclei" "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
install_go_tool "dnsx" "github.com/projectdiscovery/dnsx/cmd/dnsx"

# OWASP Amass (Standard)
install_go_tool "amass" "github.com/owasp-amass/amass/v4/.../cmd/amass"

# Update Nuclei Templates
if command -v nuclei &> /dev/null; then
    echo -e "${BLUE}[*] Updating Nuclei Templates...${NC}"
    nuclei -update-templates -silent
fi

# Python Tools
TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tools"
if [ ! -d "$TOOLS_DIR/cloud_enum" ]; then
    echo -e "${BLUE}[*] Cloning cloud_enum...${NC}"
    git clone https://github.com/initstring/cloud_enum.git "$TOOLS_DIR/cloud_enum"
    pip3 install -r "$TOOLS_DIR/cloud_enum/requirements.txt" --break-system-packages 2>/dev/null || pip3 install -r "$TOOLS_DIR/cloud_enum/requirements.txt" 2>/dev/null
fi

echo -e "${GREEN}[+] Tool verification complete.${NC}"
