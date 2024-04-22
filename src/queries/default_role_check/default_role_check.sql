select role, grantee_name, default_role
from SNOWFLAKE.ACCOUNT_USAGE."GRANTS_TO_USERS" join "SNOWFLAKE"."ACCOUNT_USAGE"."USERS"
on users.name = grants_to_users.grantee_name
where role = 'ACCOUNTADMIN'
and grants_to_users.deleted_on is null
and users.deleted_on is null
order by grantee_name;
