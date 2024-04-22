-- Allows specified role ('sentry_sis_role' in this case) to deploy the application in own account
USE ROLE ACCOUNTADMIN;
GRANT CREATE APPLICATION PACKAGE ON ACCOUNT TO ROLE sentry_sis_role; -- To create the initial package
GRANT CREATE APPLICATION ON ACCOUNT TO ROLE sentry_sis_role; -- To deploy the package

-- Stored procedure allows a non-ACCOUNTADMIN to grant access to SNOWFLAKE database to the application
CREATE DATABASE IF NOT EXISTS srv;
CREATE OR REPLACE SCHEMA srv.sentry_na_deploy;
GRANT USAGE ON DATABASE SRV TO ROLE sentry_sis_role;
GRANT USAGE ON SCHEMA srv.sentry_na_deploy TO ROLE sentry_sis_role;

CREATE OR REPLACE PROCEDURE SUDO_GRANT_IMPORTED_PRIVILEGES(APP_NAME VARCHAR)
RETURNS BOOLEAN
LANGUAGE JAVASCRIPT
STRICT
COMMENT = 'Allows granting access to SNOWFLAKE database to applications as a non-ACCOUNTADMIN user'
EXECUTE AS OWNER
AS
$$
var cmd = "GRANT IMPORTED PRIVILEGES ON DATABASE snowflake TO APPLICATION IDENTIFIER(:1)";
var stmt = snowflake.createStatement(
          {
          sqlText: cmd,
          binds: [APP_NAME]
          }
          );
var result1 = stmt.execute();
result1.next();
return result1.getColumnValue(1);
$$;

GRANT USAGE ON PROCEDURE SUDO_GRANT_IMPORTED_PRIVILEGES(VARCHAR) TO ROLE sentry_sis_role;

