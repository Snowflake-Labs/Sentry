---
title: Service Account Activity Monitoring
Tile Identifier: SECRETS-11
Dashboard: Secrets & Privileged Access
MITRE ATT&CK (SaaS): [
"T1078.004 - Valid Accounts: Cloud Accounts"
]
blurb: "Monitor service account usage patterns for anomalies that could indicate compromise or misuse."
---

Service accounts are non-human accounts used by applications, scripts, and automated processes
to access Snowflake. They often have elevated privileges and long-lived credentials, making
them high-value targets for attackers. This query monitors service account activity patterns
to detect anomalies.

**Detection Criteria:**
The query identifies service accounts by naming convention (containing 'svc', 'service', or
'app') and flags unusual activity patterns:
- **Multiple IPs**: More than 3 distinct IP addresses in a single hour
- **High query volume**: More than 1000 queries in a single hour

**Service Account Risks:**
- **Credential theft**: Service account credentials are often stored in code or config files
- **Lateral movement**: Compromised service accounts can access multiple systems
- **Privilege escalation**: Service accounts often have broad permissions
- **Persistent access**: Long-lived credentials provide ongoing access
- **Limited monitoring**: Service account activity may not be closely watched

**Anomaly Indicators:**
- Service account used from multiple geographic locations simultaneously
- Sudden spike in query volume
- Activity during unusual hours (if service runs on schedule)
- Access from unexpected IP addresses
- New types of queries or operations
- Access to data outside normal scope

**Legitimate Scenarios:**
- Distributed applications running across multiple servers
- Load balancers with multiple exit IPs
- Scheduled jobs with variable execution times
- Legitimate scaling of application infrastructure

**Recommended Actions:**
- Investigate service accounts with unusual IP patterns
- Verify that high query volumes are expected
- Review the types of queries being executed
- Check if service account credentials have been rotated recently
- Correlate with application deployment or scaling events
- Implement service account best practices:
  - Use key pair authentication instead of passwords
  - Rotate credentials regularly
  - Apply principle of least privilege
  - Use separate service accounts for different applications
  - Implement network policies to restrict source IPs
  - Monitor for credential exposure in code repositories
  - Use secrets management systems (HashiCorp Vault, AWS Secrets Manager)
  - Set up alerts for unusual service account activity
  - Document expected behavior for each service account
  - Regularly audit service account permissions

