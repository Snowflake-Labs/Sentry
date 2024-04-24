---
title: Login failures, by User and Reason
Tile Identifier: AUTH-1
Dashboard: Authentication
# Security Features Checklist:
NIST 800-53: [ AC-7 ]
NIST 800-171: [ 3.5 ]
HITRUST CSF v9: [ PR.DS-5:G5 ]
MITRE ATT&CK (SaaS): [ "T1110- Brute Force" ]
sproc_return_types:
  USER_NAME: String
  ERROR_MESSAGE: String
  NUM_OF_FAILURES: Integer
---

<!-- TODO -->
