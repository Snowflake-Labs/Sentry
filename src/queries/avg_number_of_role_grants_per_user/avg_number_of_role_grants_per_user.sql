with role_grants_per_user (user, role_count) as (
select grantee_name as user, count(*) role_count from SNOWFLAKE.ACCOUNT_USAGE.grants_to_users where deleted_on is null group by grantee_name order by role_count desc)
select round(avg(role_count),1) from role_grants_per_user;
