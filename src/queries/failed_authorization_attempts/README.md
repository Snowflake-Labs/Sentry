---
title: Failed Authorization Attempts
Tile Identifier: AUTH-4
Dashboard: Authentication
MITRE ATT&CK (SaaS): [
"T1078 - Valid Accounts",
"T1087 - Account Discovery"
]
blurb: "Track failed authorization attempts that could indicate privilege escalation attempts or reconnaissance."
---

This query monitors failed queries due to insufficient privileges, which could indicate:

**Security Threats:**
- **Privilege escalation attempts**: Users trying to access resources beyond their authorization
- **Account compromise**: Attackers probing for accessible resources
- **Reconnaissance**: Mapping out the environment and identifying valuable targets
- **Insider threats**: Employees attempting to access unauthorized data

**Operational Issues:**
- Incorrect role assignments
- Users lacking necessary privileges for legitimate work
- Application misconfigurations
- Role hierarchy issues

The query focuses on repeated failures (3+ attempts) to filter out one-off mistakes and
identify patterns of unauthorized access attempts.

**Recommended Actions:**
- Investigate users with high failure counts
- Review the objects they're attempting to access
- Verify if access requests are legitimate and adjust privileges if needed
- Check for compromised accounts if access patterns are unusual
- Correlate with login history for suspicious authentication patterns
- Review role assignments and privilege grants
- Implement principle of least privilege
- Set up alerts for repeated authorization failures
- Consider implementing request-based access workflows for sensitive data

