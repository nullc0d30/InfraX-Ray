#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 04: Exposure Discovery (Ports)
# Wraps: naabu
# Output: findings.json (Partial)

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

IP_LIST="$OUTPUT_DIR/processed/mod03_ips.txt"
JSON_OUTPUT="$OUTPUT_DIR/raw/naabu.json"
EXPOSURE_JSON="$OUTPUT_DIR/processed/findings_ports.json"

echo -e "${BLUE}[*] [04] Discovering Exposure (Ports)...${NC}"

if [ ! -s "$IP_LIST" ]; then
    echo -e "${YELLOW}[!] No IPs to scan.${NC}"
    exit 0
fi

if command -v $NAABU_BIN &> /dev/null; then
    # Profile Tuning
    case $PROFILE in
        stealth)
            PORTS="top-100"
            RATE=10
            ;;
        aggressive)
            PORTS="-"
            RATE=1000
            ;;
        *)
            PORTS="top-1000"
            RATE=$RATE_LIMIT
            ;;
    esac

    echo -e "${BLUE}[*] Running Naabu ($PROFILE mode, ports: $PORTS)...${NC}"
    
    $NAABU_BIN -list "$IP_LIST" \
    -silent \
    -json \
    -rate "$RATE" \
    -o "$JSON_OUTPUT" \
    -p "$PORTS" > /dev/null 2>&1

    # Standardize Output
    # We want: { "asset": "1.2.3.4", "type": "port", "value": 80, "severity": "info" }
    
    echo -e "${BLUE}[*] Normalizing Port Data...${NC}"
    
    # Cap ports per asset to avoid noise (e.g. if a firewall shows 1000 ports open)
    # This complex logic is best done in python/jq. Using jq to group and slice.
    
    cat "$JSON_OUTPUT" | jq -s --argjson max "$MAX_PORTS_PER_ASSET" '
        group_by(.ip) | 
        map(
            if length > $max then 
                .[0:$max] | .[] | . + {truncated: true}
            else 
                .[] 
            fi
        ) |
        map({
            asset: .host,
            ip: .ip,
            type: "exposure",
            subtype: "open_port",
            value: .port,
            severity: "info",
            description: "Port \(.port) is open"
        })
    ' > "$EXPOSURE_JSON"
    
    count=$(jq '. | length' "$EXPOSURE_JSON")
    echo -e "${GREEN}[+] Discovery complete: $count exposed ports.${NC}"

else
    echo -e "${RED}[!] Naabu not found.${NC}"
fi
