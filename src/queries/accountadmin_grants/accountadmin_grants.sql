select
    user_name || ' granted the ' || role_name || ' role on ' || end_time as Description, query_text as Statement
from
    SNOWFLAKE.ACCOUNT_USAGE.query_history
where
    execution_status = 'SUCCESS'
    and query_type = 'GRANT'
    and query_text ilike '%grant%accountadmin%to%'
order by
    end_time desc;
