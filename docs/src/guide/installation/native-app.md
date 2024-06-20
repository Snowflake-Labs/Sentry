# Native application

It is possible to install Sentry as a native application. Currently it is not
available on Snowflake marketplace, but using steps below it's possible to
install it in one account and use private listings to share it within the
organization.

Deployment steps requires [Snowflake cli][snowcli]. While it is possible to
create the application using UI and SQL, `snow` allows to save quite a bit of
time.

1. Install [Snowflake cli][snow-install] and [configure a
   connection][snow-conf].
2. Clone the [source code repository][src]
3. Change directory to `deployment_models/native-app`
4. Adjust `snowflake.yml` to suit your environment (see below section for
   dedicated deployment role)
5. Run `snow app run`

## Restricting the deployment role

This SQL allows setting up a role that can only deploy a native application.
Using it is optional but recommended.

```sql
{{#include ../../../../deployment_models/native-app/setup.sql}}
```

The exact names for objects can be adjusted as needed.

[src]: https://github.com/Snowflake-Labs/Sentry
[snowcli]: https://github.com/Snowflake-Labs/snowflake-cli
[snow-install]: https://docs.snowflake.com/developer-guide/snowflake-cli-v2/installation/installation
[snow-conf]: https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/connecting/specify-credentials
