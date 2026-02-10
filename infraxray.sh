#!/bin/bash
# Copyright (c) 2026 NullC0d3. All rights reserved.
# Made by NullC0d3


# InfraX-Ray: Opinionated Attack Surface Intelligence Automation
# Main Orchestrator

# --- Global Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/defaults.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "CRITICAL: Config file not found at $CONFIG_FILE"
    exit 1
fi

# --- Colors & Aesthetics ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Helper Functions ---
function print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
    ____      ____           _  __      ____             
   /  _/___  / __/________ _| |/ /____ / __ \____ ___  __
   / // __ \/ /_/ ___/ __ \/   // ___// /_/ / __ \/ / / /
 _/ // / / / __/ /  / /_/ /   |/ /   / _, _/ /_/ / /_/ / 
/___/_/ /_/_/ /_/   \__,_/_/|_/_/   /_/ |_|\__,_/\__, /  
                                                /____/   By NullC0d3
EOF
    echo -e "${NC}"
    echo -e "${BLUE}InfraX-Ray v2.0${NC} :: Opinionated Attack Surface Intelligence"
    echo -e "${YELLOW}Mode: ${PROFILE^^} | Safe-by-Default${NC}"
    echo "------------------------------------------------------------"
}

function usage() {
    print_banner
    echo -e "${GREEN}Usage:${NC} ./infraxray.sh [command] [target] [options]"
    echo ""
    echo -e "${BLUE}Commands:${NC}"
    echo "  scan <domain>      Start a full infrastructure scan"
    echo "  report <domain>    Regenerate reports from existing data"
    echo "  clean <domain>     Archive and cleanup target data"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo "  --profile <name>   Set profile (stealth, balanced, aggressive) [Default: balanced]"
    echo "  --deep             Deep scan (overrides profile to aggressive)"
    echo "  --cloud-only       Skip host recon, focus on cloud buckets"
    echo "  --no-vulns         Skip active vulnerability scanning"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./infraxray.sh scan example.com"
    echo "  ./infraxray.sh scan example.com --profile stealth"
    exit 1
}

function log() {
    mkdir -p "$LOG_DIR"
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$TIMESTAMP] [$2] $3" >> "$LOG_DIR/infraxray.log"
    
    # Console Output (Minimalist)
    if [ "$2" == "INFO" ]; then
        echo -e "${BLUE}[*] $3${NC}"
    elif [ "$2" == "SUCCESS" ]; then
        echo -e "${GREEN}[+] $3${NC}"
    elif [ "$2" == "WARN" ]; then
        echo -e "${YELLOW}[!] $3${NC}"
    elif [ "$2" == "ERROR" ]; then
        echo -e "${RED}[x] $3${NC}" >&2
    elif [ "$2" == "DEBUG" ]; then
        if [ "$VERBOSE" = true ]; then echo -e "${YELLOW}[D] $3${NC}"; fi
    fi
}

function run_module() {
    MODULE_SCRIPT="$1"
    MODULE_NAME="$2"
    
    # Check if module exists
    if [ ! -f "$MODULE_SCRIPT" ]; then
        log "CORE" "ERROR" "Module $MODULE_NAME not found at $MODULE_SCRIPT"
        return 1
    fi
    
    log "CORE" "INFO" "Executing: $MODULE_NAME"
    chmod +x "$MODULE_SCRIPT"
    
    # Run in subshell to prevent env pollution, capture exit code
    # Pass all context via ENV vars or Args
    # We pass args: TARGET PROJECT_ROOT PROFILE_VARS...
    
    "$MODULE_SCRIPT" "$TARGET" "$PROJECT_ROOT" "$PROFILE"
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        log "CORE" "SUCCESS" "$MODULE_NAME completed successfully."
    else
        log "CORE" "WARN" "$MODULE_NAME reported issues (Exit Code: $EXIT_CODE). Pipeline continuing..."
    fi
}

# --- Main Logic ---

if [ $# -lt 2 ]; then usage; fi

COMMAND="$1"
TARGET="$2"
shift 2
OPTIONS="$@"

# 1. Parse Options & Apply Profile
for opt in $OPTIONS; do
    case $opt in
        --profile)
            shift
            PROFILE="$1"
            ;;
        --deep)
            PROFILE="aggressive"
            ;;
        --cloud-only)
            export CLOUD_ONLY=true
            ;;
        --no-vulns)
            export NO_VULNS=true
            ;;
    esac
done

# Validate Profile & Set Constants
case $PROFILE in
    stealth)
        THREADS=5
        RATE_LIMIT=10
        TIMEOUT=15
        log "CORE" "INFO" "Profile: STEALTH (Slow, precise, minimal noise)"
        ;;
    aggressive)
        THREADS=100
        RATE_LIMIT=500
        TIMEOUT=5
        log "CORE" "WARN" "Profile: AGGRESSIVE (Loud, fast, potential blocks)"
        ;;
    *)
        PROFILE="balanced"
        THREADS=40
        RATE_LIMIT=100
        TIMEOUT=8
        log "CORE" "INFO" "Profile: BALANCED (Default trade-off)"
        ;;
esac

# Export for modules
export THREADS RATE_LIMIT TIMEOUT PROFILE PROJECT_ROOT

# Initialize Dirs
mkdir -p "$LOG_DIR"
mkdir -p "$OUTPUT_DIR/raw"
mkdir -p "$OUTPUT_DIR/processed"
mkdir -p "$OUTPUT_DIR/reports"

# 2. Execution Pipeline
case "$COMMAND" in
    scan)
        print_banner
        log "CORE" "INFO" "Initializing Scan for Target: $TARGET"
        
        # 00. Preflight
        run_module "$MODULES_DIR/00_preflight.sh" "Preflight Checks"
        
        # 01. Discovery (Skipped if cloud-only)
        if [ "$CLOUD_ONLY" != "true" ]; then
            run_module "$MODULES_DIR/01_subdomains.sh" "Asset Discovery (Subdomains)"
            run_module "$MODULES_DIR/02_alive_hosts.sh" "Asset Validation (Alive)"
            run_module "$MODULES_DIR/03_ip_mapping.sh" "Asset Enrichment (IPs)"
            run_module "$MODULES_DIR/04_ports.sh" "Exposure Discovery (Ports)"
            run_module "$MODULES_DIR/05_tech_stack.sh" "Context (Tech Stack)"
        fi
        
        # 06. Vulns (Skipped if cloud-only or no-vulns)
        if [ "$CLOUD_ONLY" != "true" ] && [ "$NO_VULNS" != "true" ]; then
            run_module "$MODULES_DIR/06_vulnerabilities.sh" "Weakness Discovery (Vulns)"
        fi
        
        # 07. Cloud
        run_module "$MODULES_DIR/07_cloud_exposure.sh" "Cloud Exposure"
        
        # 08. Scoring
        run_module "$MODULES_DIR/08_risk_scoring.sh" "Risk Intelligence Engine"
        
        # 09. Reporting
        run_module "$MODULES_DIR/09_reporting.sh" "Decision Reporting"
        
        print_banner
        echo -e "${GREEN}Scan Complete.${NC}"
        echo -e "Report: ${BLUE}$OUTPUT_DIR/reports/infraxray_$TARGET.html${NC}"
        ;;
        
    report)
        print_banner
        log "CORE" "INFO" "Regenerating reports for $TARGET"
        run_module "$MODULES_DIR/08_risk_scoring.sh" "Risk Intelligence Engine"
        run_module "$MODULES_DIR/09_reporting.sh" "Decision Reporting"
        ;;
        
    clean)
        run_module "$MODULES_DIR/10_cleanup.sh" "Cleanup"
        ;;
        
    *)
        usage
        ;;
esac
