# Streamlit in Snowflake
<!-- Disable rules: -->
<!-- - Inline HTML since mdbook uses that for macros -->

<!-- markdownlint-disable MD033 -->

These instructions will walk you through setting up Sentry as a [Streamlit in
Snowflake application][about-sis]. This approach is best if you don't want to
manage the python runtime environment.

<div class="warning">
Sentry source code is in multiple `.py` files which Snowsight editor does not
currently support. Thus Sentry cannot be deployed completely from Snowflake UI.
</div>

<!-- TODO: snowgit streamlit setup when available -->

The steps are:

1. Run the following SQL code to set up a dedicated database and role for the application.

    The created role will be have `OWNERSHIP` privilege on the application. Feel
    free to customize these steps if you would like to change the Sentry's
    runtime environment.

<!-- COMMENTs are removed since they contain CD-specific variables -->
<!-- `$ cat ../../../../nix/apps/sis/setup.sql | grep -v COMMENT` as sql -->

```sql
-- This script creates necessary objects to deploy Sentry in a separate database as a user with limited privileges.

USE ROLE useradmin;

-- User and role to deploy the Streamlit app as
CREATE OR REPLACE ROLE sentry_sis_role
;
CREATE OR REPLACE USER sentry_sis_user
    DEFAULT_NAMESPACE = sentry_db.public
    DEFAULT_ROLE = sentry_sis_role
    ;
GRANT ROLE sentry_sis_role TO USER sentry_sis_user;

USE ROLE sysadmin;

-- Database
CREATE OR REPLACE DATABASE sentry_db
;

-- Background for these permissions:
-- https://docs.snowflake.com/en/developer-guide/streamlit/owners-rights#about-app-creation
GRANT USAGE ON DATABASE sentry_db TO ROLE sentry_sis_role;
GRANT USAGE ON SCHEMA sentry_db.public TO ROLE sentry_sis_role;
GRANT CREATE STREAMLIT ON SCHEMA sentry_db.public TO ROLE sentry_sis_role;
GRANT CREATE STAGE ON SCHEMA sentry_db.public TO ROLE sentry_sis_role;

-- Warehouse
-- TODO: Drop this when issue #8 is implemented
CREATE OR REPLACE WAREHOUSE sentry WITH
    WAREHOUSE_SIZE = XSMALL
    INITIALLY_SUSPENDED = TRUE
;
GRANT USAGE ON WAREHOUSE sentry to role sentry_sis_role;

-- Grant access to SNOWFLAKE database
-- For more fine-grained access see:
-- https://docs.snowflake.com/en/sql-reference/account-usage.html#label-enabling-usage-for-other-roles
USE ROLE accountadmin;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake TO ROLE sentry_sis_role;

```

<!-- markdownlint-disable MD029 -->
2. [Set up authentication][keypair] for the created user

3. Run one of the deployment methods below to send the code into Snowflake and
   set up `STREAMLIT` object
<!-- markdownlint-enable MD029 -->

If using nix, this step is (mostly) automated through `sis-setUp` application.

## Github action

This is the easiest way to deploy the application but offers least flexibility.
The deployment is done through a GitHub action.

1. (after running SQL above) Fork/clone the [source code repository][src]
2. In the forked repository, open `Settings` > `Secrets and variables` >
   `Actions`
3. Set up following action secrets:

    - `SIS_OWNER_ROLE` – which role should own the Streamlit app
    - `SIS_GRANT_TO_ROLE` – which role should have access to the Streamlit
(e.g. `ACCOUNTADMIN`)
    - `SIS_QUERY_WAREHOUSE` – warehouse for running Streamlit
    - `SIS_APP_DATABASE` – which database should contain the Streamlit
      application
    - `SNOWFLAKE_ACCOUNT` – which Snowflake account to deploy Streamlit in
    - `SNOWFLAKE_USER` – user to authenticate
    - `SNOWFLAKE_PRIVATE_KEY` – private key to authenticate

4. Go to `Actions` and click "Run" on `Deploy Streamlit in Snowflake`

The steps above will deploy the application and grant USAGE on it to a specified
role.

Under the hood the action uses [Nix-based application](#with-nix) that you can
also run on your development machine.

## Pushing from local machine using `snowcli`

Steps in this section will use [Snowflake cli][snowcli] to deploy the
application. These options are more suitable for a development environment as
they involve some very specific tools and require familiarity with command line.

### Without Nix

1. Install [Snowflake cli][snow-install] and [configure a
   connection][snow-conf].
2. Clone the [source code repository][src]
3. Change directory to `src`
4. Adjust `snowflake.yml` to suit your environment
5. Run `snow streamlit deploy`

### With Nix

1. Have prerequisites:
    - [`nix`](https://nixos.org)
    - [`direnv`](https://direnv.net/)
2. [Configure snowcli connection][snow-conf]. Repository provides `snow` as part
   of the development shell, thus no need to install it
3. Clone the [source code repository][src]
4. Go to the cloned directory
5. Inspect, adjust `.envrc` and `.env` and allow it (`direnv allow`)
6. Run `sis-deploy`

[about-sis]: https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit
[src]: https://github.com/Snowflake-Labs/Sentry
[snowcli]: https://github.com/Snowflake-Labs/snowflake-cli
[snow-install]: https://docs.snowflake.com/developer-guide/snowflake-cli-v2/installation/installation
[snow-conf]: https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/connecting/specify-credentials
[keypair]: https://docs.snowflake.com/en/user-guide/key-pair-auth
