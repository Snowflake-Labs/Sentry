---
title: ACCOUNTADMIN Grants
Tile Identifier: ROLES-7
Dashboard: Roles
HITRUST CSF v9: PR.AC-4:G3
MITRE ATT&CK (SaaS): [
"T1060- Permission Group Discovery",
"T1078 - Privilege Escalation",
"T1546 - Event Triggered Escalation",
"T1098 - Account Manipulation"
]
blurb: "All existing and especially new AA grants should be few, rare and well-justified."
---

The “root” or superuser of your Snowflake account is an ACCOUNTADMIN (AA) role
grant.

See "Using the ACCOUNTADMIN Role" documentation [here][1].

[1]: https://docs.snowflake.com/en/user-guide/security-access-control-considerations#using-the-accountadmin-role
