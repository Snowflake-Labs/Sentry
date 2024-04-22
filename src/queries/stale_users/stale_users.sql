select name, datediff("day", nvl(last_success_login, created_on), current_timestamp()) || ' days ago' Last_Login from SNOWFLAKE.ACCOUNT_USAGE.users
where deleted_on is null
order by datediff("day", nvl(last_success_login, created_on), current_timestamp()) desc;
