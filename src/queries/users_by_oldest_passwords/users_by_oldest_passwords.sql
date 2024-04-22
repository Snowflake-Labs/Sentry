select name, datediff('day', password_last_set_time, current_timestamp()) || ' days ago' as password_last_changed from SNOWFLAKE.ACCOUNT_USAGE.users
where deleted_on is null and
password_last_set_time is not null
order by password_last_set_time;
