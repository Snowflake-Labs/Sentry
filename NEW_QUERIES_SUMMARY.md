# New Sentry Security Queries - Summary

This document provides an overview of 15 new security queries added to the Snowflake Sentry repository. These queries expand coverage across cost management, data loss prevention, authentication security, data protection, and operational monitoring.

## Quick Reference

| Query Name | Tile ID | Dashboard | MITRE ATT&CK |
|------------|---------|-----------|--------------|
| Warehouse Cost Anomalies | COST-1 | Cost & Resource Management | T1496 - Resource Hijacking |
| Warehouse Configuration Changes | COST-2 | Cost & Resource Management | T1496 - Resource Hijacking |
| Suspicious Data Exfiltration | DLP-1 | Data Loss Prevention | T1567, T1048 - Exfiltration |
| External Stage Monitoring | CONFIG-2 | Configuration | T1567 - Exfiltration Over Web Service |
| Destructive Operations Monitoring | SECRETS-12 | Secrets & Privileged Access | T1485, T1490 - Data Destruction |
| Unusual Query Execution Times | PERF-1 | Performance & Anomalies | T1496 - Resource Hijacking |
| Failed Authorization Attempts | AUTH-4 | Authentication | T1078, T1087 - Account Discovery |
| Session Hijacking Detection | AUTH-5 | Authentication | T1185 - Browser Session Hijacking |
| Unusual Login Times | AUTH-6 | Authentication | T1078 - Valid Accounts |
| Masking Policy Changes | CONFIG-3 | Configuration | T1562 - Impair Defenses |
| Row Access Policy Monitoring | CONFIG-4 | Configuration | T1562 - Impair Defenses |
| Tag-Based Access Monitoring | GOVERNANCE-1 | Data Governance | T1530 - Data from Cloud Storage |
| OAuth Token Monitoring | SECRETS-14 | Secrets & Privileged Access | T1550.001 - Application Access Token |
| Service Account Activity | SECRETS-11 | Secrets & Privileged Access | T1078.004 - Cloud Accounts |
| Failed DDL Operations | OPS-1 | Operations | T1087 - Account Discovery |

## Categories

### 1. Cost Management & Resource Monitoring (2 queries)

**Warehouse Cost Anomalies (COST-1)**
- Detects unusual credit consumption patterns using statistical analysis (z-scores)
- Identifies potential resource hijacking, crypto mining, or inefficient queries
- Analyzes 30 days of history to establish baselines
- Location: `src/queries/warehouse_cost_anomalies/`

**Warehouse Configuration Changes (COST-2)**
- Monitors changes to warehouse auto-suspend, auto-resume, and size settings
- Prevents unauthorized configuration changes that increase costs
- Tracks modifications that could enable resource abuse
- Location: `src/queries/warehouse_config_changes/`

### 2. Data Loss Prevention (3 queries)

**Suspicious Data Exfiltration (DLP-1)**
- Identifies large data exports (>1GB threshold)
- Monitors COPY, UNLOAD, GET operations, and large SELECT results
- Aggregates daily export activity per user
- Location: `src/queries/suspicious_data_exfiltration/`

**External Stage Monitoring (CONFIG-2)**
- Tracks creation, modification, and usage of external stages (S3, Azure, GCS)
- Monitors COPY operations to external locations
- Identifies potential data exfiltration channels
- Location: `src/queries/external_stage_monitoring/`

**Destructive Operations Monitoring (SECRETS-12)**
- Monitors DROP DATABASE, DROP SCHEMA, DROP TABLE, TRUNCATE TABLE operations
- Detects potential data destruction attacks or accidents
- Provides audit trail for recovery decisions
- Location: `src/queries/destructive_operations_monitoring/`

### 3. Performance & Anomaly Detection (1 query)

**Unusual Query Execution Times (PERF-1)**
- Identifies queries with abnormally long execution times (z-score > 3)
- Detects resource hijacking, inefficient queries, or malicious activity
- Establishes per-user baselines for query performance
- Location: `src/queries/unusual_query_execution_times/`

### 4. Enhanced Authentication Security (3 queries)

**Failed Authorization Attempts (AUTH-4)**
- Tracks repeated failed access attempts (3+ failures)
- Identifies privilege escalation attempts or reconnaissance
- Monitors insufficient privilege errors
- Location: `src/queries/failed_authorization_attempts/`

**Session Hijacking Detection (AUTH-5)**
- Detects IP address changes within active sessions
- Identifies potential session token theft
- Focuses on changes within 60-minute windows
- Location: `src/queries/session_hijacking_detection/`

**Unusual Login Times (AUTH-6)**
- Establishes per-user login patterns using quartile analysis
- Flags logins outside typical hours (>3 hours from normal range)
- Detects compromised accounts or insider threats
- Location: `src/queries/unusual_login_times/`

### 5. Data Protection & Governance (3 queries)

**Masking Policy Changes (CONFIG-3)**
- Monitors CREATE, ALTER, DROP, SET, UNSET operations on masking policies
- Protects PII, PHI, PCI, and other sensitive data
- Tracks 90 days of policy changes
- Location: `src/queries/masking_policy_changes/`

**Row Access Policy Monitoring (CONFIG-4)**
- Tracks changes to row-level security policies
- Monitors multi-tenant data isolation controls
- Detects policy weakening or removal
- Location: `src/queries/row_access_policy_monitoring/`

**Tag-Based Access Monitoring (GOVERNANCE-1)**
- Monitors access to objects with sensitive classification tags
- Supports compliance auditing (GDPR, HIPAA, PCI-DSS, etc.)
- Tracks PII, SENSITIVE, CONFIDENTIAL, PHI, PCI tagged objects
- Location: `src/queries/tag_based_access_monitoring/`

### 6. Privileged Access & Secrets (2 queries)

**OAuth Token Monitoring (SECRETS-14)**
- Tracks OAuth security integration changes
- Monitors third-party application access
- Detects unauthorized integrations or token abuse
- Location: `src/queries/oauth_token_monitoring/`

**Service Account Activity (SECRETS-11)**
- Monitors non-human account usage patterns
- Detects multiple IPs (>3) or high query volume (>1000/hour)
- Identifies compromised service accounts
- Location: `src/queries/service_account_activity/`

### 7. Operations & Troubleshooting (1 query)

**Failed DDL Operations (OPS-1)**
- Tracks failed CREATE, ALTER, DROP operations
- Identifies permission issues and reconnaissance attempts
- Monitors 7 days of DDL failures
- Location: `src/queries/failed_ddl_operations/`

## Integration with Existing Sentry Framework

All queries follow the established Sentry patterns:

### File Structure
```
src/queries/<query_name>/
├── <query_name>.sql       # SQL query
└── README.md              # Documentation with metadata
```

### README Metadata Format
```yaml
---
title: Query Title
Tile Identifier: CATEGORY-#
Dashboard: Dashboard Name
MITRE ATT&CK (SaaS): [
"T#### - Technique Name"
]
blurb: "Brief description"
---
```

### Query Characteristics
- Use `SNOWFLAKE.ACCOUNT_USAGE` views for historical data
- Include descriptive output columns
- Provide time-based filtering (typically 7-90 days)
- Return actionable results with context
- Include a `Description` column for easy interpretation

## Deployment

These queries can be deployed using any of Sentry's deployment methods:

1. **Streamlit in Snowflake**: Add to the Streamlit app UI
2. **Stored Procedures**: Convert to stored procedures using the existing pattern
3. **Native Application**: Include in the native app package
4. **Direct SQL**: Execute queries directly in Snowflake worksheets

## Customization Recommendations

Several queries include parameters that should be adjusted for your environment:

1. **warehouse_cost_anomalies**: Adjust z-score threshold (currently 2)
2. **suspicious_data_exfiltration**: Modify 1GB threshold based on normal usage
3. **service_account_activity**: Update naming convention filters (svc, service, app)
4. **tag_based_access_monitoring**: Customize tag names for your classification scheme
5. **unusual_login_times**: Adjust hour deviation threshold (currently 3 hours)

## MITRE ATT&CK Coverage

These queries add detection coverage for the following MITRE ATT&CK techniques:

- **T1496**: Resource Hijacking
- **T1567**: Exfiltration Over Web Service
- **T1048**: Exfiltration Over Alternative Protocol
- **T1485**: Data Destruction
- **T1490**: Inhibit System Recovery
- **T1078**: Valid Accounts
- **T1087**: Account Discovery
- **T1185**: Browser Session Hijacking
- **T1562**: Impair Defenses
- **T1530**: Data from Cloud Storage Object
- **T1550.001**: Use Alternate Authentication Material: Application Access Token

## Compliance Support

These queries support various compliance requirements:

- **GDPR**: Personal data access monitoring, data protection
- **HIPAA**: PHI access tracking, audit trails
- **PCI-DSS**: Cardholder data access monitoring
- **SOX**: Financial data access controls
- **CCPA**: Consumer data access transparency

## Next Steps

1. **Test Queries**: Run each query in your Snowflake environment to verify results
2. **Adjust Thresholds**: Customize detection thresholds based on your baseline
3. **Integrate with SIEM**: Export results to your security monitoring platform
4. **Set Up Alerts**: Configure automated alerts for critical findings
5. **Document Baselines**: Establish what "normal" looks like for your environment
6. **Create Runbooks**: Document response procedures for each query's findings
7. **Schedule Regular Reviews**: Run queries on a regular cadence (daily/weekly)

## Contributing Upstream

If you plan to contribute these queries back to the Snowflake-Labs/Sentry repository:

1. Test thoroughly in multiple Snowflake environments
2. Ensure README documentation is complete
3. Verify MITRE ATT&CK mappings are accurate
4. Add queries to the control mapping documentation
5. Update the queries.md reference documentation
6. Follow the existing contribution guidelines

## Support and Feedback

For questions or issues with these queries:
- Review the individual README.md files for detailed documentation
- Check the main Sentry documentation at https://snowflake-labs.github.io/Sentry
- Open issues on the GitHub repository
- Consult Snowflake's ACCOUNT_USAGE documentation

---

**Created**: October 2025
**Version**: 1.0
**Author**: Security Query Enhancement Project
**Total Queries**: 15

