# InfraX-Ray Threat Model

## 🎯 Threat Landscape

This model analyzes risks associated with the **operation** of InfraX-Ray in sensitive environments.

## 1. Operational Risks (The Operator)

### 1.1. Detection & Attribution
*   **Risk**: Scanning reveals the operator's source IP.
*   **Impact**: Blocking by WAFs, legal complaints, or "hack back".
*   **Control**:
    *   **Profiles**: `stealth` profile forces low concurrency and delayed requests.
    *   **User Responsibility**: Operator *must* use VPN/Proxy. Tool does not manage proxy chains natively to avoid complexity/leaks.

### 1.2. False Positives (The "Boy Who Cried Wolf")
*   **Risk**: Tool floods SOC with low-fidelity alerts.
*   **Impact**: Tool is ignored; real risks are missed.
*   **Control**:
    *   **Severity Filtering**: Default config ignores "Info/Low" nuclei findings.
    *   **CDN Filtering**: `IGNORE_CDN` setting drops assets served by major CDNs.

## 2. Target Risks (The Infrastructure)

### 2.1. Availability Impact (DoS)
*   **Risk**: Aggressive scanning knocks over legacy servers.
*   **Impact**: Operational outage for the target.
*   **Control**:
    *   **Strict Rate Limiting**: `defaults.conf` enforces `RATE_LIMIT`.
    *   **Safe-by-Default**: The default profile is `balanced`, avoiding "masscan" style packet floods.

## 3. Data Sensitivity

### 3.1. Finding Leakage
*   **Risk**: Reports containing critical vulns (e.g., RCE) are stored in plaintext.
*   **Impact**: An attacker who compromises the operator's machine gets a roadmap to the target.
*   **Control**:
    *   **Local-First**: No data is ever sent to a third-party cloud.
    *   **Cleanup**: Module 10 allows archiving and removal of raw data.

---
*Copyright (c) 2026 NullC0d3. All rights reserved.*
