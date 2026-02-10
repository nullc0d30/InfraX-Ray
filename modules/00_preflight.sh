#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 00: Preflight Checks
# Ensures the environment is ready for a professional scan.

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

echo -e "${BLUE}[*] [00] Initiating Preflight Checks...${NC}"

# 1. Check Config
if [ -z "$PROJECT_ROOT" ]; then
    echo -e "${RED}[!] Critical: PROJECT_ROOT not set.${NC}"
    exit 1
fi

# 2. Check Input
if [ -z "$TARGET" ]; then
    echo -e "${RED}[!] Critical: No target specified.${NC}"
    exit 1
fi

# 3. Check Root (Warn only, tool is safe-by-default)
if [[ $EUID -eq 0 ]]; then
    echo -e "${YELLOW}[!] Running as root. Be careful with file permissions in output directory.${NC}"
fi

# 4. Check Connectivity
ping -c 1 8.8.8.8 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}[!] Critical: No internet connection detected.${NC}"
    exit 1
fi

# 5. Check Essential Tools
CRITICAL_TOOLS="jq curl"
MISSING_TOOLS=0
for tool in $CRITICAL_TOOLS; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}[!] Critical: '$tool' is missing.${NC}"
        MISSING_TOOLS=1
    fi
done

if [ $MISSING_TOOLS -eq 1 ]; then
    exit 1
fi

echo -e "${GREEN}[+] Preflight checks passed. Target: $TARGET (Profile: $PROFILE)${NC}"
