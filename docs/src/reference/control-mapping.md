# Control Mapping

<!-- markdownlint-disable MD013 -->
<!-- NOTE: This is generated through mdsh, do not edit by hand -->

<!-- `> nix run .#renderSentryControlMappingTable` -->

<!-- BEGIN mdsh -->
| tile_identifier        | title                                                                     | dashboard                   | security_features_checklist   | nist_800_53   | nist_800_171   | hitrust_csf_v9          | mitre_attack_saas                                                                                                                 |
|:-----------------------|:--------------------------------------------------------------------------|:----------------------------|:------------------------------|:--------------|:---------------|:------------------------|:----------------------------------------------------------------------------------------------------------------------------------|
| AUTH-1                 | Login failures, by User and Reason                                        | Authentication              |                               | AC-7          | 3.5            | PR.DS-5:G5              | T1110- Brute Force                                                                                                                |
| AUTH-3                 | Breakdown by Method                                                       | Authentication              | A5                            |               | 3.5.2, 3.5.3   | PR.AC-1:G7, G10         | T1550 - Use Alternate Authentication Material, T1556 - Modify Authentication Process                                              |
| CONFIG-1               | Network Policy Change Management                                          | Configuration               | A5                            | CM-2          | 3.1.1, 3.4.2   | PR.DS-6:G3              | T1098 - Account Manipulation                                                                                                      |
| SECRETS-2              | ACCOUNTADMINs that do not use MFA                                         | Secrets & Privileged Access | A2                            | CM-2, 3       | 3.5.2          | PR.MA-1:G3              |                                                                                                                                   |
| SECRETS-3              | Privileged Object Management                                              | Secrets & Privileged Access | A11                           |               |                | DE.CM-6:G3              |                                                                                                                                   |
| SECRETS-4              | Key Pair Bypass (Password)                                                | Secrets & Privileged Access | A6                            | AC-2(1)       |                | PR.MA-1:G3              | T1550 - Use Alternate Authentication Material                                                                                     |
| SECRETS-5              | SCIM Token Lifecycle                                                      | Secrets & Privileged Access | A2, A3                        | CM-3          |                | PR.IP-11:G1             |                                                                                                                                   |
| SECRETS-8              | Grants to PUBLIC role                                                     | Secrets & Privileged Access |                               | AC-3(1)       |                | PR.AC-4:G3              | T1098 - Account Manipulation                                                                                                      |
| SECRETS-9              | Default Role is ACCOUNTADMIN                                              | Secrets & Privileged Access |                               | AC-3          |                | PR.AC-7:G8, PR.AT-2:G2* |                                                                                                                                   |
| SECRETS-10             | Grants to unmanaged schemas outside schema owner                          | Secrets & Privileged Access | A13                           | AC-3(7)       |                | PR.AC-4:G1              |                                                                                                                                   |
| SECRETS-13             | Stale users                                                               | Secrets & Privileged Access |                               | AC-2(3)a      | 3.5.6          | PR.AC-4:G3              |                                                                                                                                   |
| USER-1                 | Most Dangerous User                                                       | Users                       |                               | AC-6          |                | PR.IP-11:G2             |                                                                                                                                   |
| USER-3                 | Users by Password Age                                                     | Users                       | A7                            | AC-2(1)       |                | PR.IP-11:G2             |                                                                                                                                   |
| ROLES-1                | User to Role Ratio (larger is better)                                     | Roles                       |                               |               |                | PR.AC-4:G1              |                                                                                                                                   |
| ROLES-2                | Average Number of Role Grants per User (~5-10)                            | Roles                       |                               |               |                | PR.AC-4:G1              |                                                                                                                                   |
| ROLES-3                | Least Used Role Grants                                                    | Roles                       |                               |               |                | PR.AC-4:G1              |                                                                                                                                   |
| ROLES-5                | Bloated roles                                                             | Roles                       |                               |               |                | PR.AC-4:G1              |                                                                                                                                   |
| ROLES-7                | ACCOUNTADMIN Grants                                                       | Roles                       |                               |               |                | PR.AC-4:G3              | T1060- Permission Group Discovery, T1078 - Privilege Escalation, T1546 - Event Triggered Escalation, T1098 - Account Manipulation |
| SHARING-1              | Reader account creation                                                   | Data Sharing                |                               |               |                |                         |                                                                                                                                   |
| SHARING-2              | Changes to shares                                                         | Data Sharing                |                               |               |                |                         |                                                                                                                                   |
| SHARING-3              | Changes to listings                                                       | Data Sharing                |                               |               |                |                         |                                                                                                                                   |
| SHARING-4              | Shares usage statistics                                                   | Data Sharing                |                               |               |                |                         |                                                                                                                                   |
| SHARING-5              | Replication usage                                                         | Data Sharing                |                               |               |                |                         |                                                                                                                                   |
| SHARING-6              | Aggregate View of Access Over Time by Consumer                            | Data Sharing                |                               |               |                |                         |                                                                                                                                   |
| SHARING-7              | Access Count By Column                                                    | Data Sharing                |                               |               |                |                         |                                                                                                                                   |
| SHARING-8              | Table Joins By Consumer                                                   | Data Sharing                |                               |               |                |                         |                                                                                                                                   |
| MAY30_TTPS_GUIDANCE-1  | Monitored IPs logins                                                      | MAY30_TTPS_GUIDANCE         |                               |               |                |                         |                                                                                                                                   |
| MAY30_TTPS_GUIDANCE-2  | Aggregate of client IPs leveraged at authentication for service discovery | MAY30_TTPS_GUIDANCE         |                               |               |                |                         |                                                                                                                                   |
| MAY30_TTPS_GUIDANCE-3  | Authentication patterns ordered by timestamp                              | MAY30_TTPS_GUIDANCE         |                               |               |                |                         |                                                                                                                                   |
| MAY30_TTPS_GUIDANCE-4  | Users with static credentials                                             | MAY30_TTPS_GUIDANCE         |                               |               |                |                         |                                                                                                                                   |
| MAY30_TTPS_GUIDANCE-5  | Monitored query history                                                   | MAY30_TTPS_GUIDANCE         |                               |               |                |                         |                                                                                                                                   |
| MAY30_TTPS_GUIDANCE-10 | Anomalous Application Access                                              | MAY30_TTPS_GUIDANCE         |                               |               |                |                         |                                                                                                                                   |
<!-- END mdsh -->