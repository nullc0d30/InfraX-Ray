# InfraX-Ray
### Decision-Oriented Attack Surface Intelligence Engine

InfraX-Ray is a production-grade, automated offensive security engine designed to provide actionable intelligence, not just raw data. It transforms disparate reconnaissance signals into a unified, risk-scored decision matrix for security operations.

---

## Executive Summary

Current reconnaissance tools suffer from a "data dumping" problem: they produce massive lists of subdomains and open ports without context, forcing analysts to manually sift through noise to find signal. 

**InfraX-Ray** solves this by focusing on **decision-oriented intelligence**. It does not merely list assets; it correlates vulnerabilities with environmental context (e.g., "Is this admin panel on a development server?") to calculate a standardized Risk Score (0-100) for every asset. This allows Security Operations Centers (SOCs), Red Teams, and vulnerability managers to ignore the noise and immediately prioritize high-risk exposures.

## Core Design Philosophy

1.  **Asset-Centric Data Model**: We track *Assets* (unique hosts/IPs) as the primary unit of intelligence, not isolated tool outputs.
2.  **Deterministic Scoring**: Risk is calculated using a transparent, rule-based algorithm. There is no "Black Box" AI or opaque heuristics.
3.  **Safe-by-Default**: The engine is pre-configured with operational profiles (Stealth, Balanced, Aggressive) to ensure stability in production environments.
4.  **Noise Reduction**: CDN endpoints (Cloudflare, Akamai) and redundant assets are aggressively filtered to prevent alert fatigue.
5.  **Reconnaissance Only**: InfraX-Ray is strictly a non-exploitative intelligence gathering tool. It identifies doors but does not attempt to open them.

## What InfraX-Ray Is — and Is Not

### What It Is
*   **An Automated Intelligence Engine**: Orchestrates multiple tools into a coherent pipeline.
*   **A Decision Support System**: Prioritizes findings based on calculated risk.
*   **Auditable & Transparent**: Every finding is traceable to a specific tool output.

### What It Is Not
*   **A Continuous Monitoring Platform**: InfraX-Ray is a point-in-time assessment tool.
*   **An Exploitation Framework**: It does not execute payloads, brute-force credentials, or pivot.
*   **A "Magic Button"**: It requires a skilled operator to interpret the final intelligence.

## Target Audience

*   **Enterprise Security Teams**: Specifically for Shadow IT discovery and attack surface reduction audits.
*   **Red Team Operations**: For rapid initial footprinting and vector identification during engagement startup.
*   **Blue Teams / SOC**: For validating external alerts and enriching incident data.
*   **Government & Critical Infrastructure**: For compliance-focused asset inventory and exposure checks where data sovereignty is paramount.
*   **Bug Bounty Hunters**: To automate low-level enumeration and focus manual effort on high-probability targets.

## High-Level Architecture

InfraX-Ray operates on a **Pipeline-Filter** architecture. Data flows linearly through distinct stages, with normalization occurring at each boundary.

1.  **Ingestion**: Domain/IP input is accepted.
2.  **Discovery**: Subdomains and hosts are identified.
3.  **Enrichment**: Live assets are enriched with port, technology, and cloud data.
4.  **Risk Scoring**: Factors are weighed to produce a numerical risk score.
5.  **Reporting**: Data is synthesized into human-readable and machine-parsable artifacts.

Critically, the **Risk Scoring Engine** is decoupled from the discovery tools, allowing the logic to be tuned independently of the underlying scanners.

## Execution Pipeline

The engine executes the following modular workflow:

1.  **Preflight Checks**: Verifies environment health, dependencies, and root privileges.
2.  **Asset Discovery**: Enumerates subdomains using passive sources.
3.  **Validation**: Verifies which assets are live and responsive.
4.  **IP Mapping**: Resolves hosts to IP addresses for infrastructure correlation.
5.  **Exposure Discovery**: Scans for open ports and services.
6.  **Context Analysis**: Fingerprints technology stacks (CMS, Web Servers, OS).
7.  **Vulnerability Scanning**: Checks for known CVEs and misconfigurations (Safe checks only).
8.  **Cloud Enumeration**: Identifies associated public cloud buckets.
9.  **Risk Intelligence**: Calculates risk scores based on aggregated findings.
10. **Reporting**: Generates final artifacts.

## Risk Scoring Model

InfraX-Ray utilizes a deterministic scoring model (0-100) to classify asset risk.

*   **CRITICAL (80-100)**: Immediate remediation required. (e.g., RCE vulnerability on an exposed admin panel).
*   **HIGH (50-79)**: Priority investigation. (e.g., Exposed database port or high-severity CVE).
*   **MEDIUM (20-49)**: Scheduled remediation. (e.g., Outdated software, non-critical misconfiguration).
*   **LOW (0-19)**: Informational / Acceptable risk.

**Drivers:**
*   **Vulnerability Severity**: Base score derived from CVSS ratings of confirmed findings.
*   **Context Modifiers**: Additive weights for high-risk contexts (Example: `Dev/Staging` subdomain + `Login Panel` = Higher Risk).

## Output Artifacts

| Artifact | Format | Purpose |
| :--- | :--- | :--- |
| `report.html` | HTML | **Executive Dashboard**. High-level summary for stakeholders. |
| `risk.json` | JSON | **Intelligence Feed**. detailed risk breakdown for every asset. |
| `assets.json` | JSON | **Inventory**. Clean list of all validated assets and IPs. |
| `findings.json` | JSON | **Vulnerability Data**. Aggregated technical findings. |
| `report.json` | JSON | **SIEM Integration**. Single consolidated file for Splunk/ELK ingestion. |
| `report.txt` | Text | **CLI Summary**. Concise output for terminal review. |

## Installation

InfraX-Ray is designed for Linux environments (Debian/Ubuntu preferred).

```bash
# Clone the repository
git clone https://github.com/nullc0d30/InfraX-Ray.git

# Enter directory
cd InfraX-Ray

# Run the installer (Sudo required for dependency management)
sudo ./install.sh
```

**Note**: The installer handles all dependencies, including Go-based tools and Python libraries. Please review `install.sh` before running in sensitive environments.

## Usage

### Standard Scan (Balanced Profile)
Recommended for most use cases.
```bash
./infraxray.sh scan example.com
```

### Stealth Scan
Reduces concurrency and rate limits to minimize detection probability.
```bash
./infraxray.sh scan example.com --profile stealth
```

### Report Generation Only
Regenerates reports from existing data without re-scanning.
```bash
./infraxray.sh report example.com
```

## Security, Safety & Ethics

**InfraX-Ray is an offensive security tool for authorized testing only.**

*   **Reconnaissance Only**: This tool performs enumeration and scanning. It does **not** exploit vulnerabilities, execute payloads, or pivot boundaries.
*   **No Brute Force**: InfraX-Ray does not attempt to brute-force credentials.
*   **Operator Responsibility**: The user is solely responsible for ensuring they have written authorization to scan the target infrastructure.
*   **Legal Compliance**: Use of this tool must comply with all applicable local, state, and federal laws.

## Enterprise & Government Readiness

InfraX-Ray is engineered for rigorous environments:
*   **Auditability**: All actions and findings are logged locally.
*   **Data Sovereignty**: No data is sent to external cloud services or APIs.
*   **Predictability**: Deterministic behavior ensures consistent results across multiple runs.
*   **CI/CD Compatible**: CLI-first design allows integration into security pipelines.

## Limitations

*   **Not a Penetration Test**: This tool automates intelligence gathering; it does not replace a human penetration tester.
*   **No Zero-Day Discovery**: Vulnerability detection relies on known signatures and misconfigurations.
*   **Perimeter Only**: Designed for external attack surface management; not optimized for internal network lateral movement.

## Roadmap

*   **Scheduler Mode**: Native cron support for periodic monitoring.
*   **API Integration**: Webhooks for Slack/Teams alerts on Critical findings.
*   **Data Persistence**: Optional SQLite backend for longitudinal tracking.
*   **Diff Engine**: Alerting on new assets discovered since the last scan.

## License & Disclaimer

Copyright (c) 2026 NullC0d3. All rights reserved.

This software is provided "as is", without warranty of any kind. The authors are not responsible for any damage or legal issues caused by the use of this tool.
