#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 05: Context (Tech Stack)
# Wraps: whatweb (primary) OR httpx (fallback)
# Output: findings_tech.json

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

ASSETS_JSON="$OUTPUT_DIR/processed/assets.json"
TECH_JSON="$OUTPUT_DIR/processed/findings_tech.json"
TEMP_URLS="$OUTPUT_DIR/raw/urls_for_whatweb.txt"

echo -e "${BLUE}[*] [05] Gathering Context (Tech Stack)...${NC}"

if [ ! -s "$ASSETS_JSON" ]; then
    exit 0
fi

# 1. Prepare Target List (URLs)
jq -r '.[] | .url' "$ASSETS_JSON" | grep -v "null" > "$TEMP_URLS"

if [ ! -s "$TEMP_URLS" ]; then
    echo -e "${YELLOW}[!] No URLs to fingerprint.${NC}"
    exit 0
fi

# 2. Run WhatWeb
# WhatWeb is slow. If stealth/balanced, maybe rely on httpx. 
# But for "professional grade" whatweb is better.
# We limit recursion and aggression.

if command -v whatweb &> /dev/null; then
    WHATWEB_OUT="$OUTPUT_DIR/raw/whatweb.json"
    
    # Aggression 1 = Stealthy/Passive
    $WHATWEB_BIN --input-file "$TEMP_URLS" \
        --log-json "$WHATWEB_OUT" \
        --color=never --no-errors \
        --aggression 1 \
        --user-agent "Mozilla/5.0 (Compatible; InfraX-Ray)" > /dev/null 2>&1
        
    # Normalize
    # We filter out common noisy tech if IGNORE_TECH is set
    
    jq -s --arg ignore "$IGNORE_TECH" '
        flatten | 
        map({
            asset: .target,
            type: "context",
            subtype: "technology",
            value: .plugins | keys[],
            severity: "info"
        }) |
        # Filter Ignored Tech
        filter(
            .value as $v | 
            ($ignore | split(",") | index($v | ascii_downcase) | not)
        )
    ' "$WHATWEB_OUT" > "$TECH_JSON"

else
    echo -e "${YELLOW}[!] WhatWeb not found. Falling back to HTTPX tech data.${NC}"
    
    # Extract tech from assets.json (which came from httpx)
    jq 'map({
        asset: .url,
        type: "context",
        subtype: "technology",
        value: .tech[],
        severity: "info"
    })' "$ASSETS_JSON" > "$TECH_JSON"
fi

count=$(jq '. | length' "$TECH_JSON")
echo -e "${GREEN}[+] Context gathered: $count technology fingerprints.${NC}"
