-- This is the setup script that runs while installing a Snowflake Native App in a consumer account.
-- To write this script, you can familiarize yourself with some of the following concepts:
-- Application Roles
-- Versioned Schemas
-- UDFs/Procs
-- Extension Code
-- Refer to https://docs.snowflake.com/en/developer-guide/native-apps/creating-setup-script for a detailed understanding of this file. 

CREATE APPLICATION ROLE app_public;
CREATE OR ALTER VERSIONED SCHEMA core;
GRANT USAGE ON SCHEMA core TO APPLICATION ROLE app_public;

CREATE STREAMLIT core.sentry_streamlit
  FROM '/streamlit'
  MAIN_FILE = '/Authentication.py'
;


GRANT USAGE ON STREAMLIT core.sentry_streamlit TO APPLICATION ROLE app_public;
