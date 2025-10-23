---
title: Warehouse Configuration Changes
Tile Identifier: COST-2
Dashboard: Cost & Resource Management
MITRE ATT&CK (SaaS): [
"T1496 - Resource Hijacking"
]
blurb: "Monitor changes to warehouse auto-suspend settings and sizes that could increase costs."
---

This query tracks modifications to warehouse configurations that directly impact compute costs,
including:

- **Auto-suspend settings**: Disabling or increasing auto-suspend timeout can leave warehouses
  running unnecessarily, consuming credits
- **Auto-resume settings**: Changes to auto-resume behavior
- **Warehouse size changes**: Scaling up warehouses increases credit consumption per hour

Unauthorized or malicious changes to these settings could result in:
- Significant cost increases
- Resource abuse for unauthorized workloads
- Crypto mining or other resource hijacking

**Recommended Actions:**
- Review all warehouse configuration changes for business justification
- Implement change approval workflows for warehouse modifications
- Set up resource monitors with credit quotas
- Restrict warehouse creation/modification privileges to specific roles
- Monitor for warehouses that remain active beyond normal business hours

