# Sentry Trust Center Extension

A [Trust Center extension](https://docs.snowflake.com/en/user-guide/trust-center/trust-center-extensions#develop-a-trust-center-extension)
based on [Snowflake Sentry](https://github.com/Snowflake-Labs/Sentry) security scanners.


## Scanner packages


### Secrets & Privileged Access

Scans for security risks related to credential management, privileged access grants, and sensitive configuration changes that could expose the account to unauthorized access.

| Scanner | Type | Description |
|---------|------|-------------|
| Stale users | VULNERABILITY | Detects inactive user accounts |
| Grants to PUBLIC role | DETECTION | Detects privileges granted to all users |
| Privileged object changes | DETECTION | Monitors changes to sensitive objects |
| SCIM token lifecycle | VULNERABILITY | Alerts on expiring SCIM tokens |
| Grants to unmanaged schemas | VULNERABILITY | Detects grants bypassing schema ownership |
| Default role is ACCOUNTADMIN | VULNERABILITY | Users defaulting to full admin privileges |


### Roles

Scans for security risks in role-based access control including overly permissive roles, dangerous role grants, and unused access that violates least-privilege principles.

| Scanner | Type | Description |
|---------|------|-------------|
| ACCOUNTADMIN grants | DETECTION | Detects grants of full admin access |
| Bloated Roles | VULNERABILITY | Roles with excessive privileges |
| Least Used Role Grants | VULNERABILITY | Identifies dormant role assignments |


### Users

Scans for security risks related to user accounts including excessive access concentration, stale credentials, and accounts that may pose elevated risk if compromised.

| Scanner | Type | Description |
|---------|------|-------------|
| Most dangerous user | VULNERABILITY | Users with concentrated access |
| Users by Password Age | VULNERABILITY | Detects stale passwords |


### Configuration

Scans for changes to security-critical configurations that control network access, authentication policies, and account-level settings.

| Scanner | Type | Description |
|---------|------|-------------|
| Network policy changes | DETECTION | Monitors network access control changes |


### Authentication

Scans for authentication-related security events including failed login attempts that may indicate credential attacks or account compromise attempts.

| Scanner | Type | Description |
|---------|------|-------------|
| Number of login failures | DETECTION | Detects potential credential attacks |


### Sharing

Scans for changes to data sharing configurations including shares, listings, and reader accounts that could expose data to unintended external parties.

| Scanner | Type | Description |
|---------|------|-------------|
| Reader account creation | DETECTION | Detects new external access points |
| Listing changes monitor | DETECTION | Monitors Marketplace listing changes |
| SHAREs changes monitor | DETECTION | Monitors data share modifications |
