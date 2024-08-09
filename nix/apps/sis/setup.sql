-- This script creates necessary objects to deploy Sentry in a separate database as a user with limited privileges.

USE ROLE useradmin;

-- User and role to deploy the Streamlit app as
CREATE OR REPLACE ROLE sentry_sis_role
    COMMENT = 'Created by Sentry setup script, rev &{ rev }'
;
CREATE OR REPLACE USER sentry_sis_user
    DEFAULT_NAMESPACE = sentry_db.public
    DEFAULT_ROLE = sentry_sis_role
    COMMENT = 'Created by Sentry setup script, rev &{ rev }'
    ;
GRANT ROLE sentry_sis_role TO USER sentry_sis_user;

USE ROLE sysadmin;

-- Database
CREATE OR REPLACE DATABASE sentry_db
    COMMENT = 'Created by Sentry setup script, rev &{ rev }'
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
    COMMENT = 'Created by Sentry setup script, rev &{ rev }'
;
GRANT USAGE ON WAREHOUSE sentry to role sentry_sis_role;

-- Grant access to SNOWFLAKE database
-- For more fine-grained access see:
-- https://docs.snowflake.com/en/sql-reference/account-usage.html#label-enabling-usage-for-other-roles
USE ROLE accountadmin;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake TO ROLE sentry_sis_role;

