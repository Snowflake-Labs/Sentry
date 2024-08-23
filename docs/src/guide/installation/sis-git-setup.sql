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
    COMMENT = 'Created by Sentry setup script, rev &{ rev }'
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
