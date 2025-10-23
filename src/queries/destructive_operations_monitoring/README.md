---
title: Destructive Operations Monitoring
Tile Identifier: SECRETS-12
Dashboard: Secrets & Privileged Access
MITRE ATT&CK (SaaS): [
"T1485 - Data Destruction",
"T1490 - Inhibit System Recovery"
]
blurb: "Track destructive operations that could indicate malicious activity, accidents, or insider threats."
---

This query monitors potentially destructive database operations that could result in data loss:

- **DROP DATABASE**: Complete database deletion
- **DROP SCHEMA**: Schema and all contained objects deleted
- **DROP TABLE**: Individual table deletion
- **TRUNCATE TABLE**: All data removed from table (structure remains)

These operations are high-risk and should be carefully monitored as they could indicate:

**Malicious Activity:**
- Ransomware or destructive attacks
- Insider threats attempting to cause damage
- Compromised accounts being used to destroy evidence
- Sabotage by disgruntled employees

**Operational Issues:**
- Accidental deletions due to human error
- Automated processes with incorrect logic
- Testing/development operations in production

**Recommended Actions:**
- Investigate all destructive operations for business justification
- Verify the user's identity and authorization
- Check if Time Travel or Fail-safe can recover the data
- Review whether proper change management procedures were followed
- Implement additional approval workflows for DROP operations
- Restrict DROP privileges to specific roles
- Enable object tagging to prevent accidental deletion of critical objects
- Consider implementing a "soft delete" pattern for critical tables
- Set up alerts for destructive operations in production environments
- Maintain regular backups and test recovery procedures

