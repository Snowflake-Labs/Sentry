---
title: Suspicious Data Exfiltration Patterns
Tile Identifier: DLP-1
Dashboard: Data Loss Prevention
MITRE ATT&CK (SaaS): [
"T1567 - Exfiltration Over Web Service",
"T1048 - Exfiltration Over Alternative Protocol"
]
blurb: "Identify large or unusual data exports that could indicate data theft or insider threats."
---

This query detects potential data exfiltration by monitoring large data transfers including:

- **COPY/UNLOAD operations**: Direct data exports to external stages
- **GET operations**: Downloading data from internal stages
- **Large SELECT results**: Queries returning more than 100MB of data

The query aggregates daily export activity per user and flags any day where more than 1GB
of data was exported. This threshold can be adjusted based on your organization's normal
data transfer patterns.

**Indicators of Potential Exfiltration:**
- Unusual volume of data exports by a single user
- Exports during non-business hours
- Exports by users who don't normally perform such operations
- Sudden spike in export activity
- Exports to unfamiliar external locations

**Recommended Actions:**
- Investigate users with unusually high export volumes
- Review the specific queries and data being exported
- Check if external stages point to authorized cloud storage
- Correlate with login history to verify user identity
- Implement data loss prevention policies and monitoring
- Consider implementing column-level security and masking for sensitive data

