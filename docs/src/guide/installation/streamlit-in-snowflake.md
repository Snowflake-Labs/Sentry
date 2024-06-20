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

1. Run SQL to set up a dedicated database and role for the application:

    ```sql
    USE ROLE useradmin;

    -- User and role to deploy the Streamlit app as
    CREATE OR REPLACE ROLE sentry_sis_role;

    USE ROLE sysadmin;

    -- Database
    CREATE OR REPLACE DATABASE sentry_db;
    -- https://docs.snowflake.com/en/developer-guide/streamlit/owners-rights#about-app-creation
    GRANT USAGE ON DATABASE sentry_db TO ROLE sentry_sis_role;
    GRANT USAGE ON SCHEMA sentry_db.public TO ROLE sentry_sis_role;
    GRANT CREATE STREAMLIT ON SCHEMA sentry_db.public TO ROLE sentry_sis_role;
    GRANT CREATE STAGE ON SCHEMA sentry_db.public TO ROLE sentry_sis_role;

    -- Warehouse
    CREATE OR REPLACE WAREHOUSE sentry
        WITH
        WAREHOUSE_SIZE = XSMALL
        INITIALLY_SUSPENDED = TRUE
    ;
    GRANT USAGE ON WAREHOUSE sentry to role sentry_sis_role;

    -- Grant access to SNOWFLAKE database
    USE ROLE ACCOUNTADMIN;
    GRANT IMPORTED PRIVILEGES ON DATABASE snowflake TO ROLE sentry_sis_role;
    ```

    The created role will be have `OWNERSHIP` privilege on the application. Feel
    free to customize these steps if you would like to change the Sentry's
    runtime environment.

2. Run one of the deployment methods below to send the code into Snowflake and
   set up `STREAMLIT` object

## Github action

This is the easiest way to deploy the application but offers least flexibility.
The deployment is done through a GitHub action.

1. (after running SQL above) Fork/clone the [source code repository][src]
2. In the forked repository, open `Settings` > `Secrets and variables` >
   `Actions`
3. Set up following action secrets:

    - `SIS_GRANT_TO_ROLE` – which role should have access to the Streamlit\
(e.g. `ACCOUNTADMIN`)
    - `SIS_QUERY_WAREHOUSE` – warehouse for running Streamlit
    - `SNOWFLAKE_ACCOUNT` – which Snowflake account to deploy Streamlit in
    - `SNOWFLAKE_DATABASE` – which Snowflake database to deploy Streamlit in
    - `SNOWFLAKE_SCHEMA` – which Snowflake schema to deploy Streamlit in
    - `SNOWFLAKE_USER` – user to authenticate
    - `SNOWFLAKE_PASSWORD` – password to authenticate
    - `SNOWFLAKE_ROLE` – authentication role
    - `SNOWFLAKE_WAREHOUSE` – warehouse to execute deployment queries

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
    - `nix`
    - [`direnv`](https://direnv.net/)
2. Clone the [source code repository][src]
3. Go to the cloned directory
4. Inspect, adjust `.envrc` and allow it (`direnv allow`)
5. Run `deploy-streamlit-in-snowflake`

The repository provides a wrapper around `snow` that allows pulling the
credentials from `.envrc`, so there is no need to set up `snow` authentication.

[about-sis]: https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit
[src]: https://github.com/Snowflake-Labs/Sentry
[snowcli]: https://github.com/Snowflake-Labs/snowflake-cli
[snow-install]: https://docs.snowflake.com/developer-guide/snowflake-cli-v2/installation/installation
[snow-conf]: https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/connecting/specify-credentials
