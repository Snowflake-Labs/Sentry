# Trust Center extension

Sentry can be deployed as a [Trust Center extension][tc-ext-doc], registering
its security scanners with the Snowflake Trust Center. Once registered, the
scanners run on a schedule managed by Trust Center and findings appear in
Snowsight alongside built-in scanner packages.

This deployment model does not use the Streamlit UI. It is a good fit when you
want Sentry findings integrated into the Trust Center workflow and queryable
through the `SNOWFLAKE.TRUST_CENTER.FINDINGS` view.

## Prerequisites

- [Snowflake CLI][snow-install] installed and [configured][snow-conf]
- A role with the following privileges:
  - `SNOWFLAKE.TRUST_CENTER_ADMIN` application role
  - `CREATE APPLICATION PACKAGE`
  - `CREATE APPLICATION`

See [Trust Center access control requirements][tc-ext-doc] for details on
granting these privileges.

## Step 1: Deploy the application

Clone the [source code][src] and change directory to the Trust Center extension
deployment model:

```shell
git clone https://github.com/Snowflake-Labs/Sentry.git
cd Sentry/deployment_models/trust-center-scanner
```

Deploy the native application using Snowflake CLI:

```shell
snow app run
```

This creates the application package `SENTRY_TRUST_CENTER_EXTENSION_PKG` and the
application `SENTRY_TRUST_CENTER_EXTENSION`.

## Step 2: Grant privileges

The extension needs access to `SNOWFLAKE.ACCOUNT_USAGE` views and must expose
its `trust_center_integration_role` to the Trust Center. Run the following as
`ACCOUNTADMIN`:

```sql
-- Allow the application to read ACCOUNT_USAGE views
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE
  TO APPLICATION SENTRY_TRUST_CENTER_EXTENSION;

-- Expose the integration role to Trust Center
GRANT APPLICATION ROLE SENTRY_TRUST_CENTER_EXTENSION.trust_center_integration_role
  TO APPLICATION snowflake;
```

## Step 3: Register the extension

Register the application as a Trust Center extension:

```sql
CALL SNOWFLAKE.TRUST_CENTER.REGISTER_EXTENSION(
  'APPLICATION PACKAGE',
  'SENTRY_TRUST_CENTER_EXTENSION_PKG',
  'SENTRY_TRUST_CENTER_EXTENSION');
```

After registration, the scanner packages will appear in Snowsight under
**Governance & Security > Trust Center > Manage scanners**.

## Step 4: Enable scanner packages

Enable each scanner package you want to activate. For example, to enable the
`SECRETS_AND_PRIV_ACCESS` package:

```sql
CALL SNOWFLAKE.TRUST_CENTER.SET_CONFIGURATION(
  'ENABLED',
  'TRUE',
  'APPLICATION PACKAGE',
  'SENTRY_TRUST_CENTER_EXTENSION_PKG',
  'SECRETS_AND_PRIV_ACCESS');
```

Repeat for each scanner package you want to enable. The available scanner
packages are:

| Scanner package | Scanners | Description |
|---|---|---|
| `SECRETS_AND_PRIV_ACCESS` | 6 | Stale users, grants to PUBLIC, privileged object changes, SCIM token lifecycle, grants to unmanaged schemas, default role checks |
| `ROLES_SCANNER` | 3 | ACCOUNTADMIN grants, bloated roles, least used role grants |
| `USER_SCANNER` | 2 | Most dangerous user, users by oldest passwords |
| `CONFIG_SCANNER` | 1 | Network policy changes |
| `AUTHENTICATION_SCANNER` | 1 | Number of login failures |
| `SHARING_SCANNER` | 3 | Reader account creation, listing changes, share alterations |

You can also enable scanner packages through Snowsight by navigating to
**Governance & Security > Trust Center > Manage scanners** and toggling the
packages on.

## Step 5: Run scanners (optional)

Once enabled, scanners will run on the schedule configured in Trust Center. To
trigger an immediate run:

```sql
CALL SNOWFLAKE.TRUST_CENTER.EXECUTE_SCANNER(
  'APPLICATION PACKAGE',
  'SENTRY_TRUST_CENTER_EXTENSION_PKG',
  'SECRETS_AND_PRIV_ACCESS');
```

## Viewing findings

See the [Usage section on viewing findings](../usage/README.md#viewing-trust-center-findings).

## Deregistering the extension

To remove the extension from Trust Center:

```sql
CALL SNOWFLAKE.TRUST_CENTER.DEREGISTER_EXTENSION(
  'APPLICATION PACKAGE',
  'SENTRY_TRUST_CENTER_EXTENSION_PKG',
  'SENTRY_TRUST_CENTER_EXTENSION');
```

After deregistering, you can drop the application and package using `snow app
teardown` or manually:

```sql
DROP APPLICATION IF EXISTS SENTRY_TRUST_CENTER_EXTENSION;
DROP APPLICATION PACKAGE IF EXISTS SENTRY_TRUST_CENTER_EXTENSION_PKG;
```

[tc-ext-doc]: https://docs.snowflake.com/en/user-guide/trust-center/trust-center-extensions
[snow-install]: https://docs.snowflake.com/developer-guide/snowflake-cli-v2/installation/installation
[snow-conf]: https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/connecting/specify-credentials
[src]: https://github.com/Snowflake-Labs/Sentry
