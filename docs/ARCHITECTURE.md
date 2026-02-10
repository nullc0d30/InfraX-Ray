# InfraX-Ray Architecture

## 🏗️ System Design

InfraX-Ray follows a **Pipeline-Filter** architecture pattern, optimized for stability, data integrity, and noise reduction. It is not just a wrapper script; it is a structured engine that normalizes data at every stage.

### Core Components

1.  **Orchestrator (`infraxray.sh`)**
    *   State management.
    *   Profile enforcement (Stealth/Balanced/Aggressive).
    *   Error containment.

2.  **Data Lake (`output/`)**
    *   **Raw**: Direct tool outputs (amass.txt, nuclei.json).
    *   **Processed**: Normalized data models (`assets.json`, `findings.json`).
    *   **Reports**: Final decision artifacts.

3.  **Logic Engine (`modules/`)**
    *   **00-03**: Asset Discovery & Validation (Subdomains -> IPs -> Validation).
    *   **04-07**: Context & Exposure (Ports -> Tech -> Cloud -> Vulns).
    *   **08**: Scoring Engine (Deterministic Algorithm).
    *   **09**: Reporting Engine (Visualization).

### Data Flow Diagram

```mermaid
graph TD
    User[User Command] --> Orch[Orchestrator]
    Orch --> Pre[00_Preflight]
    Pre --> Disc[01_Subdomains]
    Disc --> RawSub[Raw Subdomains]
    RawSub --> Val[02_Alive_Hosts]
    Val --> Assets[assets.json (Initial)]
    Assets --> Enr[03_IP_Mapping]
    Enr --> Context[04-07 Context Modules]
    Context --> Findings[findings.json]
    Findings --> Scorer[08_Risk_Scoring]
    Scorer --> Risk[risk.json]
    Risk --> Reporter[09_Reporting]
    Reporter --> HTML[Dashboard]
```

## 🛡️ Reliability Features

*   **Atomic writes**: Modules write to temp files and move on success to prevent partial data corruption.
*   **Sentinel checks**: Each module validates its input before running (`jq` validation for JSON).
*   **Graceful Degradation**: If `nuclei` fails, the pipeline continues, simply noting zero vulnerabilities.

## 🧠 Decision Engine

The core value of InfraX-Ray is the **Scoring Module**, which ingests distinct data streams and applies a weighted algorithm to prioritize assets. See `SCORING_MODEL.md` for details.

---
*Copyright (c) 2026 NullC0d3. All rights reserved.*
