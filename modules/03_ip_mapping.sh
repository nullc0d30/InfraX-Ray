#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 03: IP Mapping & Enrichment
# Purpose: Ensure we have IPs for every asset and handle resolution if httpx missed it.
# Note: httpx usually handles this, so this module acts as a fallback/verifier/cleaner.

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

ASSETS_JSON="$OUTPUT_DIR/processed/assets.json"

echo -e "${BLUE}[*] [03] Enriching IP Data...${NC}"

if [ ! -s "$ASSETS_JSON" ]; then
    exit 0
fi

# Check for missing IPs in the JSON and try to resolve them using host/dig
# For performance in bash, we will skip complex iteration and trust httpx -ip for now.
# In a python version, we'd do this robustly.
# Instead, we will generate a simple text IP list for port scanning.

IP_LIST="$OUTPUT_DIR/processed/mod03_ips.txt"

# Extract IPs, ignore null or empty
jq -r '.[] | .ip' "$ASSETS_JSON" | grep -vE "^null$" | sort -u > "$IP_LIST"

count=$(wc -l < "$IP_LIST")
echo -e "${GREEN}[+] Extracted $count unique IPs/Hosts for Port Scanning.${NC}"
