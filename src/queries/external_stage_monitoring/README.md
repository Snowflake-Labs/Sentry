---
title: External Stage Security Monitoring
Tile Identifier: CONFIG-2
Dashboard: Configuration
MITRE ATT&CK (SaaS): [
"T1567 - Exfiltration Over Web Service"
]
blurb: "Monitor creation and usage of external stages that could be used for data exfiltration."
---

External stages provide direct connectivity to cloud storage (AWS S3, Azure Blob, Google Cloud
Storage) and represent a significant data exfiltration risk if not properly controlled. This
query monitors:

- **Stage creation**: New external stages pointing to cloud storage
- **Stage modifications**: Changes to existing stage configurations
- **Stage deletions**: Removal of stages (potentially covering tracks)
- **COPY operations**: Data being copied to/from stages

**Security Risks:**
- Unauthorized external stages pointing to attacker-controlled storage
- Modification of legitimate stages to redirect data
- COPY operations to external stages during unusual times
- Stages created with overly permissive credentials

**Recommended Actions:**
- Review all external stage creation for business justification
- Verify that external stage URLs point to authorized cloud storage
- Audit credentials used for external stages (AWS keys, Azure SAS tokens, etc.)
- Implement approval workflows for external stage creation
- Restrict CREATE STAGE privilege to specific roles
- Monitor COPY operations to external stages for unusual patterns
- Consider using storage integrations instead of embedding credentials
- Implement network policies to restrict where stages can be accessed from

