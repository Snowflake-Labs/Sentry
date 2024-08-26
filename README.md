This is a repository containing the Streamlit version of the [Snowflake
security dashboards][1].

![Main page screenshot](./docs/assets/main_page.png "Sentry main page screenshot")

# About

This project is first and foremost a set of tools aimed to help with step #2 of
CIRP incident response, **identification**. It is not meant to be a complete
end-to-end solution, but rather a reference implementation that needs to be
adapted to the company's needs.

This project contains a set of queries with reference information that explains
what kind of information those queries provide.

The provided tools can be used individually through stored procedures.
Alternatively, the project contains a Streamlit in Snowflake UI that can be
deployed as:

- a Streamlit application
- Snowflake native application
- docker image
- stored procedures

Alternatively the queries are kept as `.sql` files in a [dedicated directory][4]
with accompanying README files.

# Deployment

Sentry can be quickly deployed using the Git integration with Streamlit in
Snowflake:

```sql
-- Optional: set up dedicated role to own the Streamlit app
USE ROLE useradmin;
CREATE OR REPLACE ROLE sentry_sis_role;
GRANT ROLE sentry_sis_role TO ROLE sysadmin;
-- End of role setup

-- Optional: database setup
USE ROLE sysadmin;
CREATE OR REPLACE DATABASE sentry_db;
-- End of database setup

-- Optional: if using a custom warehouse
-- TODO: Drop this when issue #8 is implemented
CREATE OR REPLACE WAREHOUSE sentry WITH
    WAREHOUSE_SIZE = XSMALL
    INITIALLY_SUSPENDED = TRUE
;
GRANT USAGE ON WAREHOUSE sentry to ROLE sentry_sis_role;
-- End of warehouse setup

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE API INTEGRATION gh_snowflake_labs
    API_PROVIDER = GIT_HTTPS_API
    API_ALLOWED_PREFIXES = ('https://github.com/Snowflake-Labs')
    ENABLED = TRUE;

USE ROLE sysadmin;
CREATE OR REPLACE GIT REPOSITORY sentry_db.public.sentry_repo
    API_INTEGRATION = GH_SNOWFLAKE_LABS
    ORIGIN = 'https://github.com/Snowflake-Labs/Sentry/';

-- Optional, if using custom role
GRANT USAGE ON DATABASE sentry_db TO ROLE sentry_sis_role;
GRANT USAGE ON SCHEMA sentry_db.public TO ROLE sentry_sis_role;
GRANT READ ON GIT REPOSITORY sentry_db.public.sentry_repo TO ROLE sentry_sis_role;
GRANT CREATE STREAMLIT ON SCHEMA sentry_db.public TO ROLE sentry_sis_role;
USE ROLE accountadmin;
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE sentry_sis_role;
USE ROLE sentry_sis_role;
--

CREATE OR REPLACE STREAMLIT sentry_db.public.sentry
    ROOT_LOCATION = '@sentry_db.public.sentry_repo/branches/main/src'
    MAIN_FILE = '/Authentication.py'
    QUERY_WAREHOUSE = SENTRY; -- Replace the warehouse if needed

-- Share the streamlit app with needed roles
GRANT USAGE ON STREAMLIT sentry_db.public.sentry TO ROLE SYSADMIN;
```

# See also

Additional information, including installation and upgrade instructions is
available on the [Sentry documentation website][doc].

[1]:
https://quickstarts.snowflake.com/guide/security_dashboards_for_snowflake/index.html

[4]: ./src/queries

[doc]: https://snowflake-labs.github.io/Sentry
