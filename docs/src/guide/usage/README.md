# Usage

## Streamlit application

The queries that Sentry provides are separated into Streamlit pages. Each page
contains a set of queries with more details on each query collapsed in an
expander:

![Main page screenshot annotated](../../assets/main_page_annotated_light.png
"Main page screenshot annotated")

The details typically contain SQL text of the query and in some cases some
additional information.

## Viewing Trust Center findings

If Sentry is deployed as a [Trust Center extension](../installation/trust-center-extension.md),
findings are accessible in two ways.

### Through Snowsight

Navigate to **Governance & Security > Trust Center** and select the
**Violations** tab. Findings from Sentry's scanner packages appear alongside
built-in Trust Center findings and can be filtered by scanner package, severity,
and status.

### Through SQL

Query the `SNOWFLAKE.TRUST_CENTER.FINDINGS` view directly. For example, to get
the latest result from each scanner:

```sql
SELECT
    SCANNER_PACKAGE_ID,
    SCANNER_ID,
    COMPLETION_STATUS,
    END_TIMESTAMP,
    AT_RISK_ENTITIES,
    ERROR_MESSAGE
FROM SNOWFLAKE.TRUST_CENTER.FINDINGS
WHERE EXTENSION_NAME = 'SENTRY_TRUST_CENTER_EXTENSION'
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY SCANNER_ID
    ORDER BY END_TIMESTAMP DESC
) = 1;
```

To filter by a specific scanner package:

```sql
SELECT
    SCANNER_ID,
    COMPLETION_STATUS,
    END_TIMESTAMP,
    AT_RISK_ENTITIES
FROM SNOWFLAKE.TRUST_CENTER.FINDINGS
WHERE EXTENSION_NAME = 'SENTRY_TRUST_CENTER_EXTENSION'
  AND SCANNER_PACKAGE_ID ILIKE 'SECRETS_AND_PRIV_ACCESS'
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY SCANNER_ID
    ORDER BY END_TIMESTAMP DESC
) = 1;
```

