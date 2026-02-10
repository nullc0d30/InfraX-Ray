#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# Module 08: Intelligence Engine (Risk Scoring)
# Purpose: Deterministic Risk Calculation
# Output: risk.json

TARGET="$1"
PROJECT_ROOT="$2"
PROFILE="$3"

source "$PROJECT_ROOT/config/defaults.conf"

# Inputs
ASSETS_JSON="$OUTPUT_DIR/processed/assets.json"
PORTS_JSON="$OUTPUT_DIR/processed/findings_ports.json"
TECH_JSON="$OUTPUT_DIR/processed/findings_tech.json"
VULN_JSON="$OUTPUT_DIR/processed/findings_vulns.json"
CLOUD_JSON="$OUTPUT_DIR/processed/findings_cloud.json"

# Output
RISK_JSON="$OUTPUT_DIR/processed/risk.json"

echo -e "${BLUE}[*] [08] Calculating Risk Intelligence...${NC}"

# Check inputs exist (create empty if missing)
for f in "$ASSETS_JSON" "$PORTS_JSON" "$TECH_JSON" "$VULN_JSON" "$CLOUD_JSON"; do
    if [ ! -f "$f" ]; then echo "[]" > "$f"; fi
done

# We use jq to join all data and calculate scores based on logic.
# This is a complex jq query.

jq -n \
    --slurpfile assets "$ASSETS_JSON" \
    --slurpfile ports "$PORTS_JSON" \
    --slurpfile tech "$TECH_JSON" \
    --slurpfile vulns "$VULN_JSON" \
    --slurpfile cloud "$CLOUD_JSON" \
    --argjson w_crit "$WEIGHT_CRITICAL" \
    --argjson w_high "$WEIGHT_HIGH" \
    --argjson w_med "$WEIGHT_MEDIUM" \
    --argjson w_low "$WEIGHT_LOW" \
    --argjson w_admin "$WEIGHT_EXPOSED_ADMIN" \
    --argjson w_bucket "$WEIGHT_CLOUD_BUCKET" \
    --argjson w_dev "$WEIGHT_DEV_ENV" \
    '
    ($assets | flatten) as $asset_list |
    ($ports | flatten) as $port_list |
    ($tech | flatten) as $tech_list |
    ($vulns | flatten) as $vuln_list |
    ($cloud | flatten) as $cloud_list |
    
    $asset_list | map(
        . as $a |
        .url as $u |
        
        # 1. Gather Findings for this Asset
        ($port_list | map(select(.asset == $a.asset or .ip == $a.ip))) as $my_ports |
        ($tech_list | map(select(.asset == $a.asset or .asset == $u))) as $my_tech |
        ($vuln_list | map(select(.asset | contains($a.asset)))) as $my_vulns |
        ($cloud_list | map(select(.asset | contains($a.asset)))) as $my_cloud |
        
        # 2. Calculate Base Score (Vulns)
        (
            ($my_vulns | map(select(.severity=="critical")) | length) * $w_crit +
            ($my_vulns | map(select(.severity=="high")) | length) * $w_high +
            ($my_vulns | map(select(.severity=="medium")) | length) * $w_med +
            ($my_vulns | map(select(.severity=="low")) | length) * $w_low
        ) as $score_vuln |
        
        # 3. Calculate Context Score
        # Check for Admin Panels
        (if ($my_tech | any(.value | test("admin|cpanel|ssh"; "i"))) or 
            ($my_ports | any(.value == 22 or .value == 3389)) 
         then $w_admin else 0 end) as $score_admin |
         
        # Check for Cloud Buckets
        (if ($my_cloud | length > 0) then $w_bucket else 0 end) as $score_cloud |
        
        # Check for Dev Environment
        (if ($a.asset | test("dev\\.|test\\.|staging\\."; "i")) then $w_dev else 0 end) as $score_dev |
        
        ($score_admin + $score_cloud + $score_dev) as $score_context |
        
        # 4. Total Score & Cap at 100
        ($score_vuln + $score_context) as $raw_score |
        (if $raw_score > 100 then 100 else $raw_score end) as $final_score |
        
        # 5. Determine Level
        (if $final_score >= 80 then "CRITICAL"
         elif $final_score >= 50 then "HIGH"
         elif $final_score >= 20 then "MEDIUM"
         else "LOW" end) as $risk_level |
         
        # Output Object
        {
            asset: $a.asset,
            ip: $a.ip,
            risk_score: $final_score,
            risk_level: $risk_level,
            drivers: {
                vulns: $score_vuln,
                context: $score_context
            },
            evidence: {
                vuln_count: ($my_vulns | length),
                open_ports: ($my_ports | length),
                tech_stack: ($my_tech | length),
                cloud_issues: ($my_cloud | length)
            }
        }
    ) | sort_by(-.risk_score)
    ' > "$RISK_JSON"

# Calculate Overall Environment Score (Average of top 10 risky assets to prevent dilution)
OVERALL_SCORE=$(jq '[.[] | .risk_score] | sort | reverse | .[0:10] | add / length | floor' "$RISK_JSON")
if [ "$OVERALL_SCORE" == "null" ]; then OVERALL_SCORE=0; fi

echo "{\"environment_score\": $OVERALL_SCORE}" > "$OUTPUT_DIR/processed/env_score.json"

echo -e "${GREEN}[+] Intelligence Engine complete. Overall Risk: $OVERALL_SCORE/100${NC}"
