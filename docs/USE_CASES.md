# Use Cases by Sector

## 🏢 Enterprise Security Architecture

### "The Shadow IT Audit"
**Scenario**: A CISO needs a quarterly report on all external-facing assets that are *not* behind the corporate WAF.
**Execution**:
1.  `./infraxray.sh scan company.com --profile balanced`
2.  Review `report.html` for assets with technology stack != "Corporate Standard".
3.  Ingest `assets.json` into the CMDB.

## 🦄 Bug Bounty Hunting

### "The Wide Scope Filter"
**Scenario**: A hunter picks up a program with `*.target.com` scope (10k+ subdomains).
**Execution**:
1.  Run `infraxray.sh scan target.com` on a VPS.
2.  Filter `risk.json` for risk_score > 70.
3.  Focus manual testing *only* on those top 50 assets.

## 🏛️ Government / Compliance

### "The Exposure Check"
**Scenario**: Verify that no public-facing systems are running End-of-Life (EOL) software or exposing RDP.
**Execution**:
1.  Configure `defaults.conf` to flag specific EOL versions in `IGNORE_TECH` (inverted logic).
2.  Run scan.
3.  Check `findings.json` for port 3389 or "IIS 6.0".

## ⚔️ Red Team Operations

### "The C2 Setup"
**Scenario**: Identify a weak asset to host a redirector or phish from.
**Execution**:
1.  Scan target middleware.
2.  Find forgotten development staging servers (`dev.`, `staging.`).
3.  Target these for initial foothold.

---
*Copyright (c) 2026 NullC0d3. All rights reserved.*
