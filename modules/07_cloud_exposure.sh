#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 07: External Exposure (Cloud)
# Wraps: cloud_enum
# Output: findings_cloud.json

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

CLOUD_JSON="$OUTPUT_DIR/processed/findings_cloud.json"
RAW_CLOUD="$OUTPUT_DIR/raw/cloud_enum.txt"

# Path to python script
CLOUD_ENUM_SCRIPT="$TOOLS_DIR/cloud_enum/cloud_enum.py"

echo -e "${BLUE}[*] [07] Checking Cloud Exposure...${NC}"

KEYWORD=$(echo "$TARGET" | cut -d'.' -f1)

if [ -f "$CLOUD_ENUM_SCRIPT" ]; then
    if [ "$PROFILE" == "stealth" ]; then
       echo -e "${YELLOW}[!] Skipping Cloud Enum in Stealth Mode (noisy).${NC}"
       echo "[]" > "$CLOUD_JSON"
       exit 0
    fi
    
    echo -e "${BLUE}[*] Enumerating Cloud Resources for keyword: $KEYWORD${NC}"
    
    # Run tool
    python3 "$CLOUD_ENUM_SCRIPT" -k "$KEYWORD" -l "$RAW_CLOUD" > /dev/null 2>&1
    
    # Parse output (Text to JSON)
    # Cloud Enum output is unstructured text. We grep for "OPEN" or "Protected".
    
    grep -i "OPEN" "$RAW_CLOUD" | \
    jq -R -s 'split("\n") | map(select(length > 0)) | map({
        asset: .,
        type: "exposure",
        subtype: "cloud_bucket",
        value: "Open Bucket/Blob",
        severity: "high"
    })' > "$CLOUD_JSON"
    
    count=$(jq '. | length' "$CLOUD_JSON")
    echo -e "${GREEN}[+] Cloud check complete: $count open resources.${NC}"

else
    echo -e "${YELLOW}[!] cloud_enum not found.${NC}"
    echo "[]" > "$CLOUD_JSON"
fi
