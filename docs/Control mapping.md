<!-- TODO: Add intro? -->

<!-- NOTE: This is generated through mdsh, do not edit by hand -->

<!-- markdownlint-disable MD013 -->
<!-- `> nix run .#renderSentryControlMappingTable` -->
<!-- BEGIN mdsh -->
| tile_identifier   | title                              | dashboard                   | security_features_checklist   | nist_800_53   | nist_800_171   | hitrust_csf_v9   | mitre_attack_saas            |
|:------------------|:-----------------------------------|:----------------------------|:------------------------------|:--------------|:---------------|:-----------------|:-----------------------------|
| AUTH-1            | Login failures, by User and Reason | Authentication              |                               | AC-7          | 3.5            |                  | T1110- Brute Force           |
| SECRETS-3         | Privileged Object Management       | Secrets & Privileged Access | A11                           |               |                |                  |                              |
| SECRETS-8         | Grants to PUBLIC role              | Secrets & Privileged Access |                               | AC-3(1)       |                |                  | T1098 - Account Manipulation |
| SECRETS-13        | Stale users                        | Secrets & Privileged Access |                               | AC-2(3)a      | 3.5.6          |                  |                              |
| USER-1            | Most Dangerous User                | Users                       |                               | AC-6          |                |                  |                              |
<!-- END mdsh -->
<!-- markdownlint-enable MD013 -->
