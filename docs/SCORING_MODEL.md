# InfraX-Ray Risk Scoring Model (Deterministic)

InfraX-Ray uses a rules-based engine to calculate a **Base Risk Score (0-100)** for every asset. This provides consistency and explainability—critical for executive reporting.

## 🧮 The Formula

`Risk Score = Min(100, Base Impact + Context Modifiers)`

### 1. Base Impact (Vulnerabilities)
Derived from confirmed findings (Nuclei, CVEs).

| Severity | Weight | Description |
| :--- | :--- | :--- |
| **Critical** | +50 | RCE, SQLi, Auth Bypass. Immediate action required. |
| **High** | +30 | SSRF, LFI, Stored XSS. High priority. |
| **Medium** | +10 | Reflected XSS, Misconfig. Fix in next cycle. |
| **Low** | +2 | Info disclosure. |

### 2. Context Modifiers (Exposure)
Derived from asset context (Ports, Tech, Cloud).

| Finding | Weight | Description |
| :--- | :--- | :--- |
| **Exposed Admin** | +20 | Login panels (cPanel, WP-Admin, SSH). |
| **Cloud Storage** | +25 | Public S3 Bucket / Azure Blob. |
| **Database Port** | +15 | 3306, 5432, 27017 exposed to internet. |
| **Dev Environment** | +15 | `dev.`, `test.`, `staging.` subdomains (often weaker security). |
| **EOL Software** | +10 | Detected legacy technology. |

## 📉 Example Calculation

**Asset**: `dev-admin.example.com`

1.  **Findings**:
    *   1x High Severity Vuln (Exposed .env file) -> **+30**
2.  **Context**:
    *   Exposed Admin Panel (SSH open) -> **+20**
    *   "Dev" environment keywords -> **+15**
3.  **Calculation**:
    *   30 + 20 + 15 = **65**

**Final Score**: **65 (HIGH RISK)**

## 📊 Risk Levels

*   **CRITICAL (80-100)**: Drop everything and fix.
*   **HIGH (50-79)**: Fix within 24-48 hours.
*   **MEDIUM (20-49)**: Scheduled remediation.
*   **LOW (0-19)**: Acceptable risk / Monitoring.

---
*Copyright (c) 2026 NullC0d3. All rights reserved.*
