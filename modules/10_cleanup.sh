#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 10: Cleanup & Archiving
# Purpose: Maintain hygiene and evidence chain.

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

echo -e "${BLUE}[*] [10] Archiving & Cleaning...${NC}"

ARCHIVE_DIR="$OUTPUT_DIR/archives"
mkdir -p "$ARCHIVE_DIR"

TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
ARCHIVE_NAME="case_${TARGET}_${TIMESTAMP}.tar.gz"

# Archive Raw Evidence + Reports
tar -czf "$ARCHIVE_DIR/$ARCHIVE_NAME" \
    -C "$OUTPUT_DIR" "raw" "reports" "processed" \
    --exclude "archives" > /dev/null 2>&1

if [ -f "$ARCHIVE_DIR/$ARCHIVE_NAME" ]; then
    echo -e "${GREEN}[+] Evidence archived to $ARCHIVE_DIR/$ARCHIVE_NAME${NC}"
    
    # Cleanup Processed/Raw to save space, but KEEP reports/
    # In professional setting, we might want to wipe raw to avoid accumulation
    
    rm -rf "$OUTPUT_DIR/raw"
    rm -rf "$OUTPUT_DIR/processed"
    mkdir -p "$OUTPUT_DIR/raw" "$OUTPUT_DIR/processed"
    
else
    echo -e "${RED}[!] Archive failed.${NC}"
fi
