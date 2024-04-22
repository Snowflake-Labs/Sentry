with least_used_roles (user_name, role_name, last_used, times_used) as
(select user_name, role_name, max(end_time), count(*) from SNOWFLAKE.ACCOUNT_USAGE.query_history group by user_name, role_name order by user_name, role_name)
select grantee_name,
role,
nvl(last_used, (select min(start_time) from SNOWFLAKE.ACCOUNT_USAGE.query_history)) last_used,
nvl(times_used, 0) times_used, datediff(day, created_on, current_timestamp()) || ' days ago' age
from SNOWFLAKE.ACCOUNT_USAGE.grants_to_users
left join least_used_roles on user_name = grantee_name and role = role_name
where deleted_on is null order by last_used, times_used, age desc;
