#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 02: Asset Validation (Alive Hosts)
# Wraps: httpx
# Output: JSON Assets

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

INPUT_FILE="$OUTPUT_DIR/raw/all_subdomains.txt"
JSON_OUTPUT="$OUTPUT_DIR/raw/httpx.json"
ASSETS_JSON="$OUTPUT_DIR/processed/assets.json"

echo -e "${BLUE}[*] [02] Validating Assets (Live Check)...${NC}"

if [ ! -s "$INPUT_FILE" ]; then
    echo -e "${YELLOW}[!] No subdomains to validate.${NC}"
    exit 0
fi

if command -v $HTTPX_BIN &> /dev/null; then
    # Profile Tuning
    HTTPX_THREADS=$THREADS
    if [ "$PROFILE" == "stealth" ]; then HTTPX_THREADS=2; fi

    $HTTPX_BIN -l "$INPUT_FILE" \
    -silent \
    -threads "$HTTPX_THREADS" \
    -title -tech-detect -status-code -ip -cdn \
    -json \
    -o "$JSON_OUTPUT" > /dev/null 2>&1
    
    # Process into clean assets.json structure
    # We maintain a list of objects: { "host": "sub.example.com", "ip": "1.2.3.4", "tech": [], "cdn": bool }
    
    echo -e "${BLUE}[*] Normalizing Asset Data...${NC}"
    
    # Use jq to reshape httpx output into our Asset Model
    # Filter by CDN if configured
    
    if [ "$IGNORE_CDN" == "true" ]; then
       FILTER='select(.cdn == false)'
    else
       FILTER='.'
    fi
    
    cat "$JSON_OUTPUT" | jq -s "[.[] | $FILTER | {
        asset: .input,
        url: .url,
        ip: (.a[0] // .host),
        title: .title,
        tech: (.tech // []),
        status: .status_code,
        is_cdn: .cdn
    }]" > "$ASSETS_JSON"

    count=$(jq '. | length' "$ASSETS_JSON")
    echo -e "${GREEN}[+] Validation complete: $count live assets (CDN Filter: $IGNORE_CDN).${NC}"

else
    echo -e "${RED}[!] httpx not found.${NC}"
    exit 1
fi
