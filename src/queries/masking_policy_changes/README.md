---
title: Masking Policy Changes
Tile Identifier: CONFIG-3
Dashboard: Configuration
MITRE ATT&CK (SaaS): [
"T1562 - Impair Defenses"
]
blurb: "Monitor changes to masking policies that protect sensitive data from unauthorized viewing."
---

Masking policies are critical security controls that protect sensitive data (PII, PHI, PCI, etc.)
by dynamically masking column values based on the user's role and privileges. This query monitors
all changes to masking policies, including:

- **CREATE**: New masking policies being defined
- **ALTER**: Modifications to existing masking policies
- **DROP**: Removal of masking policies
- **SET**: Application of masking policies to columns
- **UNSET**: Removal of masking policies from columns

**Security Risks:**
- **Disabling protections**: Dropping or unsetting masking policies exposes sensitive data
- **Weakening policies**: Altering policies to be less restrictive
- **Privilege escalation**: Modifying policies to grant unauthorized access
- **Compliance violations**: Changes that violate data protection regulations
- **Insider threats**: Malicious users attempting to access sensitive data

**Critical Changes to Monitor:**
- Masking policies being dropped or unset from sensitive columns
- Changes to policy conditions that broaden access
- Modifications during unusual hours or by unexpected users
- Bulk changes to multiple masking policies

**Recommended Actions:**
- Review all masking policy changes for business justification
- Verify that changes were authorized through proper change management
- Test masking policies after changes to ensure they work as expected
- Implement approval workflows for masking policy modifications
- Restrict masking policy privileges to security/compliance roles
- Maintain audit trail of all policy changes
- Document which columns should have masking policies
- Regularly review masking policy effectiveness
- Alert on any policy removals or weakening changes
- Consider implementing policy-as-code for version control

