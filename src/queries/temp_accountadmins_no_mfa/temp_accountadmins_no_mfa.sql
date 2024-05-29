select u.name, has_password,
timediff(days, last_success_login, current_timestamp()) || ' days ago' last_login ,
timediff(days, password_last_set_time,current_timestamp(6)) || ' days ago' password_age
from snowflake.account_usage.users u
join snowflake.account_usage.grants_to_users g on grantee_name = name and role in ('ACCOUNTADMIN', 'SECURITYADMIN') and g.deleted_on is null
where ext_authn_duo = false and u.deleted_on is null and has_password = true
order by last_success_login desc;

