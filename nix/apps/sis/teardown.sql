USE ROLE accountadmin;
DROP ROLE IF EXISTS sentry_sis_role;
DROP USER IF EXISTS sentry_sis_user;
DROP DATABASE IF EXISTS sentry_db;

-- TODO: Drop this when issue #8 is implemented
DROP WAREHOUSE IF EXISTS sentry;
