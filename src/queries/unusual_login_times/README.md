---
title: Unusual Login Times
Tile Identifier: AUTH-6
Dashboard: Authentication
MITRE ATT&CK (SaaS): [
"T1078 - Valid Accounts"
]
blurb: "Detect logins during unusual hours that could indicate compromised accounts or insider threats."
---

This query establishes a baseline of typical login hours for each user (based on 30 days of
history) and flags logins that occur significantly outside their normal pattern. It uses
quartile analysis to determine typical hours and alerts on logins more than 3 hours outside
the normal range.

**Security Indicators:**
- **Compromised accounts**: Attackers accessing accounts from different time zones
- **Insider threats**: Employees accessing systems during off-hours to avoid detection
- **Credential theft**: Stolen credentials being used outside normal business hours
- **Automated attacks**: Scripts or bots operating on different schedules

**Behavioral Analysis:**
The query learns each user's typical login pattern, making it effective at detecting
anomalies while reducing false positives from legitimate schedule variations.

**Legitimate Unusual Logins:**
- On-call engineers responding to incidents
- Employees working flexible hours or from different time zones
- Scheduled maintenance windows
- International travel
- Legitimate overtime work

**Recommended Actions:**
- Investigate logins significantly outside normal hours
- Verify with users if the login was legitimate
- Check the source IP address for known malicious sources
- Review query activity during the unusual session
- Correlate with other security events (failed logins, privilege escalation)
- Consider implementing time-based access controls for sensitive roles
- Require additional authentication for off-hours access
- Set up real-time alerts for unusual login times on privileged accounts
- Implement network policies that restrict access during certain hours
- Review and adjust based on legitimate business needs and schedules

