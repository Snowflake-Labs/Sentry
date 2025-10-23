---
title: Row Access Policy Monitoring
Tile Identifier: CONFIG-4
Dashboard: Configuration
MITRE ATT&CK (SaaS): [
"T1562 - Impair Defenses"
]
blurb: "Track row access policy changes that control which rows users can view based on their privileges."
---

Row Access Policies (RAPs) provide fine-grained access control by determining which rows in a
table or view are visible to users based on their role, user attributes, or other conditions.
This query monitors all changes to row access policies:

- **CREATE**: New row access policies being defined
- **ALTER**: Modifications to existing policies
- **DROP**: Removal of row access policies
- **SET**: Application of policies to tables/views
- **UNSET**: Removal of policies from tables/views

**Security Implications:**
Row access policies are critical for:
- Multi-tenant data isolation
- Regional data restrictions
- Department-level data segregation
- Customer data separation
- Compliance with data residency requirements

**Security Risks:**
- **Data exposure**: Dropping or unsetting policies may expose restricted data
- **Policy weakening**: Altering policies to grant broader access
- **Compliance violations**: Changes that violate regulatory requirements
- **Privilege escalation**: Modifying policies to access unauthorized data
- **Cross-tenant data leakage**: Policy changes that break multi-tenant isolation

**Critical Scenarios:**
- Row access policies removed from tables with sensitive data
- Policy logic changed to be more permissive
- Policies modified during off-hours or by unexpected users
- Bulk policy changes across multiple tables
- Policies dropped before table access

**Recommended Actions:**
- Review all row access policy changes for authorization
- Test policies after changes to verify correct behavior
- Implement change approval workflows for policy modifications
- Restrict row access policy privileges to security administrators
- Document which tables require row access policies
- Maintain version control of policy definitions
- Regularly audit policy effectiveness
- Alert on policy removals or significant modifications
- Verify multi-tenant isolation after policy changes
- Consider implementing automated policy testing
- Review query results to ensure proper row filtering

