# New Queries Index

Quick navigation guide for the 15 new security queries added to Sentry.

## By Category

### 💰 Cost Management & Resource Monitoring
1. [Warehouse Cost Anomalies](src/queries/warehouse_cost_anomalies/) - `COST-1`
2. [Warehouse Configuration Changes](src/queries/warehouse_config_changes/) - `COST-2`

### 🔒 Data Loss Prevention
3. [Suspicious Data Exfiltration](src/queries/suspicious_data_exfiltration/) - `DLP-1`
4. [External Stage Monitoring](src/queries/external_stage_monitoring/) - `CONFIG-2`
5. [Destructive Operations Monitoring](src/queries/destructive_operations_monitoring/) - `SECRETS-12`

### ⚡ Performance & Anomaly Detection
6. [Unusual Query Execution Times](src/queries/unusual_query_execution_times/) - `PERF-1`

### 🔐 Enhanced Authentication Security
7. [Failed Authorization Attempts](src/queries/failed_authorization_attempts/) - `AUTH-4`
8. [Session Hijacking Detection](src/queries/session_hijacking_detection/) - `AUTH-5`
9. [Unusual Login Times](src/queries/unusual_login_times/) - `AUTH-6`

### 🛡️ Data Protection & Governance
10. [Masking Policy Changes](src/queries/masking_policy_changes/) - `CONFIG-3`
11. [Row Access Policy Monitoring](src/queries/row_access_policy_monitoring/) - `CONFIG-4`
12. [Tag-Based Access Monitoring](src/queries/tag_based_access_monitoring/) - `GOVERNANCE-1`

### 🔑 Privileged Access & Secrets
13. [OAuth Token Monitoring](src/queries/oauth_token_monitoring/) - `SECRETS-14`
14. [Service Account Activity](src/queries/service_account_activity/) - `SECRETS-11`

### 🔧 Operations & Troubleshooting
15. [Failed DDL Operations](src/queries/failed_ddl_operations/) - `OPS-1`

## By Dashboard

### Cost & Resource Management
- Warehouse Cost Anomalies (COST-1)
- Warehouse Configuration Changes (COST-2)

### Data Loss Prevention
- Suspicious Data Exfiltration (DLP-1)

### Configuration
- External Stage Monitoring (CONFIG-2)
- Masking Policy Changes (CONFIG-3)
- Row Access Policy Monitoring (CONFIG-4)

### Secrets & Privileged Access
- Destructive Operations Monitoring (SECRETS-12)
- OAuth Token Monitoring (SECRETS-14)
- Service Account Activity (SECRETS-11)

### Performance & Anomalies
- Unusual Query Execution Times (PERF-1)

### Authentication
- Failed Authorization Attempts (AUTH-4)
- Session Hijacking Detection (AUTH-5)
- Unusual Login Times (AUTH-6)

### Data Governance
- Tag-Based Access Monitoring (GOVERNANCE-1)

### Operations
- Failed DDL Operations (OPS-1)

## By MITRE ATT&CK Technique

### T1496 - Resource Hijacking
- Warehouse Cost Anomalies
- Warehouse Configuration Changes
- Unusual Query Execution Times

### T1567 - Exfiltration Over Web Service
- Suspicious Data Exfiltration
- External Stage Monitoring

### T1048 - Exfiltration Over Alternative Protocol
- Suspicious Data Exfiltration

### T1485 - Data Destruction
- Destructive Operations Monitoring

### T1490 - Inhibit System Recovery
- Destructive Operations Monitoring

### T1078 - Valid Accounts
- Failed Authorization Attempts
- Unusual Login Times

### T1087 - Account Discovery
- Failed Authorization Attempts
- Failed DDL Operations

### T1185 - Browser Session Hijacking
- Session Hijacking Detection

### T1562 - Impair Defenses
- Masking Policy Changes
- Row Access Policy Monitoring

### T1530 - Data from Cloud Storage Object
- Tag-Based Access Monitoring

### T1550.001 - Application Access Token
- OAuth Token Monitoring

### T1078.004 - Cloud Accounts
- Service Account Activity

## Quick Test Commands

Test a query directly in Snowflake:
```sql
-- Example: Test warehouse cost anomalies
USE ROLE ACCOUNTADMIN;
@/path/to/sentry-repo/src/queries/warehouse_cost_anomalies/warehouse_cost_anomalies.sql
```

Or copy the SQL content and run in a worksheet.

## File Locations

All queries are located in:
```
/Users/phorrigan/sentry-repo/src/queries/
├── warehouse_cost_anomalies/
├── warehouse_config_changes/
├── suspicious_data_exfiltration/
├── external_stage_monitoring/
├── destructive_operations_monitoring/
├── unusual_query_execution_times/
├── failed_authorization_attempts/
├── session_hijacking_detection/
├── unusual_login_times/
├── masking_policy_changes/
├── row_access_policy_monitoring/
├── tag_based_access_monitoring/
├── oauth_token_monitoring/
├── service_account_activity/
└── failed_ddl_operations/
```

Each directory contains:
- `<query_name>.sql` - The SQL query
- `README.md` - Documentation with metadata and usage guidance

## Documentation

See [NEW_QUERIES_SUMMARY.md](NEW_QUERIES_SUMMARY.md) for detailed information about:
- Query descriptions and use cases
- Security indicators and recommendations
- Customization options
- Integration guidance
- Compliance mappings

