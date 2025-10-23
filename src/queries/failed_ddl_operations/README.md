---
title: Failed DDL Operations
Tile Identifier: OPS-1
Dashboard: Operations
MITRE ATT&CK (SaaS): [
"T1087 - Account Discovery"
]
blurb: "Track failed DDL operations that could indicate permission issues, attacks, or operational problems."
---

Data Definition Language (DDL) operations create, modify, or delete database objects. Failed
DDL operations can indicate security issues, permission problems, or operational challenges.
This query monitors failed DDL operations across all object types.

**Monitored Operations:**
- **CREATE**: Failed attempts to create objects (databases, schemas, tables, etc.)
- **ALTER**: Failed modifications to existing objects
- **DROP**: Failed deletion attempts

**Security Indicators:**
- **Reconnaissance**: Attackers probing for objects or permissions
- **Privilege escalation attempts**: Users trying to create/modify objects without permission
- **Account compromise**: Unusual failed operations from compromised accounts
- **Insider threats**: Employees attempting unauthorized structural changes

**Operational Indicators:**
- **Permission issues**: Users lacking necessary privileges for legitimate work
- **Syntax errors**: Malformed DDL statements
- **Object conflicts**: Attempting to create objects that already exist
- **Dependency issues**: Trying to drop objects with dependencies
- **Resource constraints**: Failures due to quota or resource limits

**Common Failure Reasons:**
- Insufficient privileges (most common security concern)
- Object already exists
- Object does not exist (for ALTER/DROP)
- Object has dependencies (for DROP)
- Invalid syntax
- Resource limits exceeded
- Network or timeout issues

**Patterns to Investigate:**
- Repeated failures by the same user
- Failures on sensitive objects (production databases, security schemas)
- Failed DROP operations (potential data destruction attempts)
- Failures during unusual hours
- Failures from unexpected roles
- Sudden increase in DDL failures

**Recommended Actions:**
- Review failed operations for security concerns
- Investigate repeated failures by the same user
- Verify if failures are from legitimate work needing permission adjustments
- Check for reconnaissance patterns (systematic probing)
- Correlate with login history for compromised account indicators
- Review role assignments and privileges
- Implement approval workflows for DDL operations in production
- Set up alerts for failed DROP operations on critical objects
- Monitor for patterns indicating automated attacks
- Document and track legitimate DDL failures for process improvement
- Consider implementing DDL auditing and change management
- Use separate environments for development and production
- Restrict DDL privileges in production environments

