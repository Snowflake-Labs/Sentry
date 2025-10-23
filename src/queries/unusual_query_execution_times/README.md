---
title: Unusual Query Execution Times
Tile Identifier: PERF-1
Dashboard: Performance & Anomalies
MITRE ATT&CK (SaaS): [
"T1496 - Resource Hijacking"
]
blurb: "Detect queries with abnormally long execution times that could indicate inefficient code or malicious activity."
---

This query identifies queries with execution times that deviate significantly from the user's
historical patterns. It calculates z-scores based on 30 days of query history and flags any
queries with a z-score greater than 3 (indicating execution time is 3+ standard deviations
above the mean).

**Potential Security Indicators:**
- Malicious queries designed to consume resources
- Data exfiltration attempts processing large datasets
- Crypto mining or other resource hijacking
- Compromised accounts running unauthorized workloads
- Queries scanning unusually large amounts of data

**Operational Indicators:**
- Poorly optimized queries needing tuning
- Missing indexes or clustering keys
- Cartesian joins or other inefficient patterns
- Queries affected by data growth
- Warehouse sizing issues

**Recommended Actions:**
- Review the query text for suspicious patterns
- Check if the user normally runs this type of query
- Analyze query profile for performance bottlenecks
- Verify data volumes being processed
- Correlate with login history to verify user identity
- Consider implementing query timeouts and resource monitors
- Review warehouse sizing and scaling policies
- Implement query result caching where appropriate

