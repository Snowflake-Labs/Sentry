# New Sentry Security Queries

This directory contains **15 new security monitoring queries** for the Snowflake Sentry application, expanding threat detection and operational visibility across your Snowflake environment.

## 📋 What's Included

### New Query Categories
- **Cost Management** (2 queries) - Detect resource abuse and cost anomalies
- **Data Loss Prevention** (3 queries) - Identify data exfiltration attempts
- **Performance Monitoring** (1 query) - Detect unusual query behavior
- **Authentication Security** (3 queries) - Enhanced login and access monitoring
- **Data Protection** (3 queries) - Policy and governance monitoring
- **Privileged Access** (2 queries) - OAuth and service account tracking
- **Operations** (1 query) - DDL failure analysis

### Coverage Expansion
- **8 new MITRE ATT&CK techniques** covered
- **4 new dashboards** (Cost Management, DLP, Performance, Data Governance)
- **15 new tile identifiers** (COST-1/2, DLP-1, AUTH-4/5/6, CONFIG-2/3/4, etc.)

## 🚀 Quick Start

### View the Queries
All queries are located in `src/queries/` with the following structure:
```
src/queries/<query_name>/
├── <query_name>.sql    # SQL query
└── README.md           # Documentation
```

### Test a Query
1. Open Snowflake and navigate to a worksheet
2. Copy the SQL from any `.sql` file
3. Run with appropriate role (typically ACCOUNTADMIN for ACCOUNT_USAGE access)

Example:
```sql
USE ROLE ACCOUNTADMIN;
-- Paste query content here
```

### Browse Documentation
- **[NEW_QUERIES_INDEX.md](NEW_QUERIES_INDEX.md)** - Quick navigation by category, dashboard, or MITRE ATT&CK
- **[NEW_QUERIES_SUMMARY.md](NEW_QUERIES_SUMMARY.md)** - Detailed overview with integration guidance
- Individual `README.md` files in each query directory - Specific query documentation

## 📊 Query Highlights

### High-Value Queries to Start With

1. **Suspicious Data Exfiltration** (`DLP-1`)
   - Detects large data exports (>1GB)
   - Critical for insider threat detection
   - Location: `src/queries/suspicious_data_exfiltration/`

2. **Session Hijacking Detection** (`AUTH-5`)
   - Identifies IP changes within sessions
   - Detects stolen credentials/tokens
   - Location: `src/queries/session_hijacking_detection/`

3. **Masking Policy Changes** (`CONFIG-3`)
   - Monitors changes to data protection policies
   - Critical for compliance
   - Location: `src/queries/masking_policy_changes/`

4. **Warehouse Cost Anomalies** (`COST-1`)
   - Detects unusual credit consumption
   - Prevents resource abuse
   - Location: `src/queries/warehouse_cost_anomalies/`

5. **Service Account Activity** (`SECRETS-11`)
   - Monitors non-human account behavior
   - Detects compromised service accounts
   - Location: `src/queries/service_account_activity/`

## 🔧 Customization

Several queries include parameters you should adjust for your environment:

| Query | Parameter | Default | Recommendation |
|-------|-----------|---------|----------------|
| warehouse_cost_anomalies | z-score threshold | 2 | Adjust based on variability |
| suspicious_data_exfiltration | Export threshold | 1GB | Set based on normal usage |
| service_account_activity | Naming pattern | svc/service/app | Match your conventions |
| tag_based_access_monitoring | Tag names | PII/PHI/PCI | Use your classification tags |
| unusual_login_times | Hour deviation | 3 hours | Adjust for shift work |

## 📈 Integration Options

### 1. Streamlit in Snowflake
Add queries to the existing Sentry Streamlit app for interactive dashboards.

### 2. Stored Procedures
Convert queries to stored procedures following the existing pattern in `docs/src/reference/queries.md`.

### 3. Scheduled Tasks
Create Snowflake tasks to run queries on a schedule:
```sql
CREATE TASK monitor_data_exfiltration
  WAREHOUSE = SENTRY
  SCHEDULE = 'USING CRON 0 */6 * * * UTC'  -- Every 6 hours
AS
  -- Query content here
;
```

### 4. SIEM Integration
Export query results to your security monitoring platform for alerting and correlation.

### 5. Direct Execution
Run queries manually in Snowflake worksheets for ad-hoc investigations.

## 🎯 Use Cases

### Security Operations
- **Incident Response**: Investigate suspicious activity
- **Threat Hunting**: Proactively search for indicators of compromise
- **Continuous Monitoring**: Regular security posture assessment

### Compliance
- **Audit Support**: Generate compliance reports
- **Access Reviews**: Track sensitive data access
- **Policy Enforcement**: Monitor security control effectiveness

### Cost Optimization
- **Resource Monitoring**: Identify wasteful compute usage
- **Anomaly Detection**: Catch unexpected cost increases
- **Capacity Planning**: Understand usage patterns

### Operations
- **Troubleshooting**: Diagnose permission and configuration issues
- **Performance Analysis**: Identify query bottlenecks
- **Change Management**: Track infrastructure modifications

## 🔐 Security Considerations

### Required Privileges
Most queries require:
- `IMPORTED PRIVILEGES` on `SNOWFLAKE` database (for ACCOUNT_USAGE views)
- `ACCOUNTADMIN` role (recommended) or custom role with appropriate grants

### Data Retention
ACCOUNT_USAGE views have different retention periods:
- LOGIN_HISTORY: 365 days
- QUERY_HISTORY: 365 days
- WAREHOUSE_METERING_HISTORY: 365 days
- TAG_REFERENCES: No retention limit

Adjust query time windows based on retention needs.

### Query Performance
- Most queries are optimized for recent data (7-90 days)
- Use appropriate warehouses (SMALL or MEDIUM typically sufficient)
- Consider materializing results for frequently-run queries

## 📚 Additional Resources

### Snowflake Documentation
- [ACCOUNT_USAGE Views](https://docs.snowflake.com/en/sql-reference/account-usage.html)
- [Security Best Practices](https://docs.snowflake.com/en/user-guide/security-best-practices.html)
- [Resource Monitors](https://docs.snowflake.com/en/user-guide/resource-monitors.html)

### Sentry Documentation
- [Main Sentry Docs](https://snowflake-labs.github.io/Sentry)
- [Original Repository](https://github.com/Snowflake-Labs/Sentry)
- [Installation Guide](https://snowflake-labs.github.io/Sentry/guide/installation/)

### MITRE ATT&CK
- [ATT&CK for Cloud](https://attack.mitre.org/matrices/enterprise/cloud/)
- [SaaS Techniques](https://attack.mitre.org/techniques/enterprise/)

## 🤝 Contributing

If you plan to contribute these queries upstream to Snowflake-Labs/Sentry:

1. **Test thoroughly** in multiple Snowflake editions and regions
2. **Document clearly** with complete README metadata
3. **Follow conventions** matching existing query patterns
4. **Update references** in control mapping and queries documentation
5. **Submit PR** with clear description of additions

## 📝 Query List

| # | Query Name | Tile ID | Category |
|---|------------|---------|----------|
| 1 | Warehouse Cost Anomalies | COST-1 | Cost Management |
| 2 | Warehouse Configuration Changes | COST-2 | Cost Management |
| 3 | Suspicious Data Exfiltration | DLP-1 | Data Loss Prevention |
| 4 | External Stage Monitoring | CONFIG-2 | Configuration |
| 5 | Destructive Operations Monitoring | SECRETS-12 | Privileged Access |
| 6 | Unusual Query Execution Times | PERF-1 | Performance |
| 7 | Failed Authorization Attempts | AUTH-4 | Authentication |
| 8 | Session Hijacking Detection | AUTH-5 | Authentication |
| 9 | Unusual Login Times | AUTH-6 | Authentication |
| 10 | Masking Policy Changes | CONFIG-3 | Configuration |
| 11 | Row Access Policy Monitoring | CONFIG-4 | Configuration |
| 12 | Tag-Based Access Monitoring | GOVERNANCE-1 | Data Governance |
| 13 | OAuth Token Monitoring | SECRETS-14 | Privileged Access |
| 14 | Service Account Activity | SECRETS-11 | Privileged Access |
| 15 | Failed DDL Operations | OPS-1 | Operations |

## 🆘 Support

For questions or issues:
1. Check individual query README files for specific documentation
2. Review the [NEW_QUERIES_SUMMARY.md](NEW_QUERIES_SUMMARY.md) for detailed guidance
3. Consult Snowflake ACCOUNT_USAGE documentation
4. Open an issue on the repository

---

**Version**: 1.0  
**Created**: October 2025  
**Total Queries**: 15  
**Total Files**: 30 (15 SQL + 15 README)  

Happy monitoring! 🎉

