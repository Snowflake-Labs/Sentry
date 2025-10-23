---
title: Session Hijacking Detection
Tile Identifier: AUTH-5
Dashboard: Authentication
MITRE ATT&CK (SaaS): [
"T1185 - Browser Session Hijacking"
]
blurb: "Detect potential session hijacking by monitoring IP address changes within active sessions."
---

This query identifies suspicious changes in client IP addresses within the same session,
which could indicate session hijacking or token theft. It focuses on IP changes that occur
within 60 minutes, as legitimate IP changes (like switching networks) typically result in
new sessions.

**Session Hijacking Indicators:**
- Same session ID used from multiple IP addresses
- Rapid IP address changes (within minutes)
- Geographic impossibilities (IPs from distant locations)
- Changes from corporate to suspicious IPs
- Session continuation after network change without re-authentication

**Legitimate Scenarios:**
- Mobile users switching between WiFi and cellular
- VPN connections/disconnections
- Load balancers or proxies with multiple exit IPs
- Corporate networks with multiple NAT gateways

**How Session Hijacking Occurs:**
- Stolen session tokens or cookies
- Man-in-the-middle attacks
- Cross-site scripting (XSS) attacks
- Malware on user devices
- Compromised authentication tokens

**Recommended Actions:**
- Investigate sessions with IP changes, especially rapid changes
- Verify with users if they changed networks during the timeframe
- Check if the new IP is from a known malicious source
- Review query activity during and after the IP change
- Consider implementing IP-based session binding
- Enforce re-authentication on network changes for sensitive operations
- Implement network policies to restrict access from untrusted IPs
- Enable MFA to add additional authentication layers
- Monitor for concurrent sessions from different locations

