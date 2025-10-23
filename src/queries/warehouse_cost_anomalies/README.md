---
title: Warehouse Cost Anomalies
Tile Identifier: COST-1
Dashboard: Cost & Resource Management
MITRE ATT&CK (SaaS): [
"T1496 - Resource Hijacking"
]
blurb: "Detect unusual compute usage patterns that could indicate compromised accounts or inefficient queries."
---

This query identifies warehouses with abnormal credit consumption patterns by calculating
z-scores for daily usage. A z-score greater than 2 indicates the warehouse consumed 
significantly more credits than its historical average, which could indicate:

- Compromised accounts running malicious queries
- Inefficient query patterns
- Runaway processes
- Resource hijacking for crypto mining or other abuse

The query analyzes the last 30 days of warehouse usage and flags any days where credit
consumption deviates significantly from the norm. This helps security teams identify
potential security incidents while also supporting cost optimization efforts.

**Recommended Actions:**
- Investigate high z-score days for unusual query patterns
- Review user activity during anomalous periods
- Check for unauthorized warehouse size changes
- Implement warehouse resource monitors with alerts

