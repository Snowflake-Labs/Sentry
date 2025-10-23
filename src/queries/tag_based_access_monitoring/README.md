---
title: Tag-Based Access Monitoring
Tile Identifier: GOVERNANCE-1
Dashboard: Data Governance
MITRE ATT&CK (SaaS): [
"T1530 - Data from Cloud Storage Object"
]
blurb: "Monitor access to objects with sensitive data classification tags for compliance and security."
---

Object tagging in Snowflake provides a powerful mechanism for data classification and governance.
This query monitors access to objects tagged with sensitive data classifications, helping
organizations track who accesses sensitive data and ensure compliance with data protection
regulations.

**Monitored Tag Classifications:**
- **PII**: Personally Identifiable Information
- **SENSITIVE**: General sensitive business data
- **CONFIDENTIAL**: Confidential business information
- **PHI**: Protected Health Information (HIPAA)
- **PCI**: Payment Card Industry data

**Use Cases:**
- **Compliance auditing**: Track access to regulated data
- **Insider threat detection**: Identify unusual access to sensitive data
- **Data governance**: Monitor sensitive data usage patterns
- **Access reviews**: Verify appropriate access to classified data
- **Incident investigation**: Trace access during security events

**Security Monitoring:**
- Users accessing sensitive data outside their normal role
- Unusual volume of access to tagged objects
- Access during non-business hours
- First-time access to highly sensitive data
- Bulk access to multiple sensitive objects

**Compliance Requirements:**
Many regulations require monitoring and auditing access to sensitive data:
- **GDPR**: Personal data access logging
- **HIPAA**: PHI access tracking
- **PCI-DSS**: Cardholder data access monitoring
- **SOX**: Financial data access controls
- **CCPA**: Consumer data access transparency

**Recommended Actions:**
- Establish and document data classification standards
- Implement consistent tagging policies across the organization
- Review access patterns to sensitive data regularly
- Investigate unusual or unauthorized access
- Implement role-based access controls aligned with data sensitivity
- Set up alerts for access to highly sensitive tags
- Conduct regular access reviews for sensitive data
- Train users on data classification and handling requirements
- Document business justification for sensitive data access
- Consider implementing additional controls (masking, encryption) for tagged data
- Customize the tag list based on your organization's classification scheme
- Integrate with SIEM for real-time alerting

