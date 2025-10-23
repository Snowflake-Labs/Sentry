---
title: OAuth Token Usage Monitoring
Tile Identifier: SECRETS-14
Dashboard: Secrets & Privileged Access
MITRE ATT&CK (SaaS): [
"T1550.001 - Use Alternate Authentication Material: Application Access Token"
]
blurb: "Track OAuth token creation and usage patterns to detect unauthorized integrations or token abuse."
---

OAuth security integrations enable external applications and services to authenticate to
Snowflake using OAuth tokens. This query monitors all activities related to OAuth integrations,
which are critical security controls for third-party application access.

**Monitored Activities:**
- **Creation**: New OAuth integrations being established
- **Modification**: Changes to existing OAuth configurations
- **Deletion**: Removal of OAuth integrations
- **Configuration changes**: Updates to OAuth parameters, scopes, or endpoints

**Security Risks:**
- **Unauthorized integrations**: Malicious OAuth integrations providing backdoor access
- **Token theft**: Stolen OAuth tokens used for unauthorized access
- **Excessive permissions**: OAuth integrations with overly broad scopes
- **Compromised applications**: Legitimate integrations that have been compromised
- **Persistent access**: OAuth tokens that remain valid after user account compromise

**OAuth Integration Components:**
- **Authorization server**: External OAuth provider (e.g., Okta, Azure AD)
- **Token endpoint**: Where tokens are obtained
- **Scopes**: Permissions granted to the OAuth application
- **Redirect URIs**: Where authorization codes are sent

**Critical Changes to Monitor:**
- New OAuth integrations created by unexpected users
- Changes to OAuth scopes or permissions
- Modifications to redirect URIs (potential for token interception)
- OAuth integrations created during off-hours
- Deletion of OAuth integrations (covering tracks)

**Recommended Actions:**
- Review all OAuth integration changes for authorization
- Verify that OAuth integrations connect to legitimate services
- Audit OAuth scopes to ensure least privilege
- Validate redirect URIs point to authorized domains
- Implement approval workflows for OAuth integration creation
- Restrict OAuth integration privileges to specific roles
- Regularly review active OAuth integrations
- Monitor OAuth token usage patterns
- Implement token rotation policies
- Set up alerts for new or modified OAuth integrations
- Document all approved OAuth integrations
- Review OAuth integration logs for suspicious activity
- Consider implementing OAuth token lifetime limits
- Validate that OAuth providers use secure authentication

