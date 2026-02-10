#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 06: Weakness Discovery (Vulnerabilities)
# Wraps: nuclei
# Output: findings_vulns.json

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

URL_LIST="$OUTPUT_DIR/raw/urls_for_whatweb.txt" # Reuse from mod05
VULN_JSON="$OUTPUT_DIR/processed/findings_vulns.json"
RAW_NUCLEI="$OUTPUT_DIR/raw/nuclei.json"

echo -e "${BLUE}[*] [06] Scanning for Weaknesses (Vulnerabilities)...${NC}"

if [ ! -s "$URL_LIST" ]; then
    echo -e "${YELLOW}[!] No URLs to scan.${NC}"
    exit 0
fi

if command -v $NUCLEI_BIN &> /dev/null; then
    
    # Profile & Severity Tuning
    SEVERITY="$NUCLEI_SEVERITY" # from defaults (critical,high,medium)
    
    RUN_OPTS="-silent -json-export $RAW_NUCLEI"
    
    if [ "$PROFILE" == "stealth" ]; then
        RUN_OPTS="$RUN_OPTS -rate-limit 10 -concurrency 5"
    elif [ "$PROFILE" == "aggressive" ]; then
        RUN_OPTS="$RUN_OPTS -rate-limit 150 -concurrency 50"
        SEVERITY="critical,high,medium,low" # Deeper
    else
        RUN_OPTS="$RUN_OPTS -rate-limit 50 -concurrency 25"
    fi

    echo -e "${BLUE}[*] Running Nuclei (Severity: $SEVERITY)...${NC}"
    
    $NUCLEI_BIN -l "$URL_LIST" \
        -severity "$SEVERITY" \
        $RUN_OPTS > /dev/null 2>&1
        
    # Normalize
    # Map Nuclei output to our Finding Schema
    
    jq -s 'map({
        asset: .matched_at,
        type: "weakness",
        subtype: "vulnerability",
        value: .info.name,
        severity: .info.severity,
        description: .info.description,
        cve: (.info.classification.cve_id // null)
    })' "$RAW_NUCLEI" > "$VULN_JSON"
    
    count=$(jq '. | length' "$VULN_JSON")
    echo -e "${GREEN}[+] Weakness scan complete: $count findings.${NC}"

else
    echo -e "${RED}[!] Nuclei not found.${NC}"
fi
