---
title: Users with static credentials
Tile Identifier: TEMP-4
Dashboard: TEMP
Security Features Checklist:
NIST 800-53:
NIST 800-171:
HITRUST CSF v9:
MITRE ATT&CK (SaaS):
blurb: "Recommendation to remove any static credentials (passwords) stored in Snowflake to mitigate the risk of credential stuffing/ password spray attacks."
---
Recommendation to remove any static credentials (passwords) stored in Snowflake
to mitigate the risk of credential stuffing/ password spray attacks.

This query will produce a user list for remediation as a password is set, user
is active, and is not enrolled in Snowflake's managed Duo MFA.

*Note*: If enforcing MFA from the customer Directory tenant (Okta Verify/ MSFT
Authenticator) this will only apply to Federated Authentication patterns and not
direct (password) authentication.

```sql
--Unset static credentials to mitigate credential stuffing attack vectors
alter user <USER> unset password;
--Disable compromised user (abort running/ scheduled queries, kill session, prevent authentication)
alter user <USER> set disabled= true;
```
