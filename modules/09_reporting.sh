#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 09: Reporting
# Purpose: Generate Decision-Oriented Artifacts

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

# Inputs
RISK_JSON="$OUTPUT_DIR/processed/risk.json"
ENV_SCORE_JSON="$OUTPUT_DIR/processed/env_score.json"
TEMPLATE="$TEMPLATES_DIR/report.html"

# Outputs
FINAL_HTML="$OUTPUT_DIR/reports/infraxray_$TARGET.html"
FINAL_JSON="$OUTPUT_DIR/reports/infraxray_$TARGET.json"
FINAL_TXT="$OUTPUT_DIR/reports/infraxray_$TARGET.txt"

echo -e "${BLUE}[*] [09] Generating Reports...${NC}"

# 1. SIEM JSON (Consolidated)
# Combine all processed data into one huge JSON
jq -n \
    --slurpfile assets "$OUTPUT_DIR/processed/assets.json" \
    --slurpfile risk "$RISK_JSON" \
    --slurpfile vulns "$OUTPUT_DIR/processed/findings_vulns.json" \
    --arg target "$TARGET" \
    --arg date "$(date)" \
    '{target: $target, scanned_at: $date, risk_profile: $risk[0], assets: $assets[0], full_findings: $vulns[0]}' \
    > "$FINAL_JSON"

# 2. HTML Report
if [ -f "$TEMPLATE" ]; then
    cp "$TEMPLATE" "$FINAL_HTML"
    
    # Extract vars
    SCORE=$(jq '.environment_score' "$ENV_SCORE_JSON")
    ASSET_COUNT=$(jq '. | length' "$OUTPUT_DIR/processed/assets.json")
    VULN_COUNT=$(jq '. | length' "$OUTPUT_DIR/processed/findings_vulns.json")
    
    # Determines class
    RISK_CLASS="risk-low"
    if [ "$SCORE" -ge 20 ]; then RISK_CLASS="risk-medium"; fi
    if [ "$SCORE" -ge 50 ]; then RISK_CLASS="risk-high"; fi
    if [ "$SCORE" -ge 80 ]; then RISK_CLASS="risk-critical"; fi
    
    # Replacements
    sed -i "s/{{TARGET}}/$TARGET/g" "$FINAL_HTML"
    sed -i "s/{{DATE}}/$(date)/g" "$FINAL_HTML"
    sed -i "s/{{RISK_SCORE}}/$SCORE/g" "$FINAL_HTML"
    sed -i "s/{{RISK_CLASS}}/$RISK_CLASS/g" "$FINAL_HTML"
    sed -i "s/{{TOTAL_ASSETS}}/$ASSET_COUNT/g" "$FINAL_HTML"
    sed -i "s/{{TOTAL_VULNS}}/$VULN_COUNT/g" "$FINAL_HTML"
    
    # Inject Top 5 Risky Assets
    # We construct HTML rows using jq
    TOP_ROWS=$(jq -r '.[0:5] | .[] | 
        "<tr><td><b>" + .asset + "</b></td>" +
        "<td>" + .ip + "</td>" +
        "<td>" + (.risk_level) + "</td>" +
        "<td>" + (.risk_score | tostring) + "</td>" +
        "<td>" + (.evidence.vuln_count | tostring) + " vulns</td></tr>"' "$RISK_JSON")
    
    # Safe Injection (Pattern-based) - This bash sed is reckless with newlines, but works for simple scenarios.
    # We use a placeholder file approach for stability.
    echo "$TOP_ROWS" > rows.tmp
    sed -i '/{{ASSETS_TABLE_ROWS}}/e cat rows.tmp' "$FINAL_HTML" 2>/dev/null || sed -i "s@{{ASSETS_TABLE_ROWS}}@$(echo $TOP_ROWS | tr '\n' ' ')@g" "$FINAL_HTML"
    rm rows.tmp
else
    echo -e "${RED}[!] Template missing.${NC}"
fi

# 3. CLI Summary
echo "=================================================" > "$FINAL_TXT"
echo " INFRAX-RAY REPORT :: $TARGET" >> "$FINAL_TXT"
echo "=================================================" >> "$FINAL_TXT"
echo " Risk Score: $SCORE / 100" >> "$FINAL_TXT"
echo " Asset Count: $ASSET_COUNT" >> "$FINAL_TXT"
echo " Vuln Count: $VULN_COUNT" >> "$FINAL_TXT"
echo "-------------------------------------------------" >> "$FINAL_TXT"
echo " TOP RISKY ASSETS:" >> "$FINAL_TXT"
jq -r '.[0:5] | .[] | " [\(.risk_level)] \(.asset) (Score: \(.risk_score)) - \(.evidence.vuln_count) vulns"' "$RISK_JSON" >> "$FINAL_TXT"
echo "=================================================" >> "$FINAL_TXT"

echo -e "${GREEN}[+] Reports generated.${NC}"
