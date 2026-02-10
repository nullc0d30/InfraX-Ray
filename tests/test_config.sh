#!/bin/bash

# Configuration Test Script
# Purpose: Verify that defaults.conf can be sourced without syntax errors.

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/defaults.conf"

echo "Testing config file at: $CONFIG_FILE"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    if [ -n "$PROFILE" ]; then
        echo -e "${GREEN}[PASS] Config sourced successfully. Profile: $PROFILE${NC}"
        exit 0
    else
        echo -e "${RED}[FAIL] Config sourced but PROFILE is empty.${NC}"
        exit 1
    fi
else
    echo -e "${RED}[FAIL] Config file not found.${NC}"
    exit 1
fi
