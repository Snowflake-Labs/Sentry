USE ROLE useradmin;

-- User and role to deploy the Streamlit app as
CREATE OR REPLACE ROLE sentry_sis_role;
CREATE OR REPLACE USER sentry_app_user;
GRANT ROLE sentry_sis_role TO USER sentry_app_user;

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

