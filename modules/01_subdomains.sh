#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 01: Subdomain Discovery
# Wraps: subfinder, amass
# Output: Asset List (not just text)

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

RAW_DIR="$OUTPUT_DIR/raw"
PROCESSED_DIR="$OUTPUT_DIR/processed"
mkdir -p "$RAW_DIR" "$PROCESSED_DIR"

echo -e "${BLUE}[*] [01] Discovering Assets (Subdomains)...${NC}"

# 1. Subfinder
if command -v $SUBFINDER_BIN &> /dev/null; then
    echo -e "${BLUE}[*] Running Subfinder...${NC}"
    $SUBFINDER_BIN -d "$TARGET" -silent -o "$RAW_DIR/subfinder.txt" > /dev/null 2>&1
else
    echo -e "${YELLOW}[!] Subfinder not found.${NC}"
    touch "$RAW_DIR/subfinder.txt"
fi

# 2. Amass (Profile Dependent)
if [ "$PROFILE" == "aggressive" ] || [ "$PROFILE" == "balanced" ]; then
    if command -v $AMASS_BIN &> /dev/null; then
        echo -e "${BLUE}[*] Running Amass (Passive)...${NC}"
        # Timeout handling is tricky with amass, best to trust it or use `timeout` cmd
        timeout 5m $AMASS_BIN enum -passive -d "$TARGET" -o "$RAW_DIR/amass.txt" -silent > /dev/null 2>&1 || echo -e "${YELLOW}[!] Amass timed out or failed.${NC}"
    else
        touch "$RAW_DIR/amass.txt"
    fi
else
    echo -e "${YELLOW}[!] Skipping Amass (Stealth Profile).${NC}"
    touch "$RAW_DIR/amass.txt"
fi

# 3. Merge & Deduplicate
cat "$RAW_DIR/subfinder.txt" "$RAW_DIR/amass.txt" 2>/dev/null | sort -u > "$RAW_DIR/all_subdomains.txt"
count=$(wc -l < "$RAW_DIR/all_subdomains.txt")

echo -e "${GREEN}[+] Discovery complete: $count unique subdomains.${NC}"
