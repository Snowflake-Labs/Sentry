select
    user_name || ' altered a share at ' || end_time as Description, execution_status, query_text as Statement
from
    SNOWFLAKE.ACCOUNT_USAGE.query_history
where
    query_type = 'ALTER'
    and query_text ilike '%alter%share%'
order by
    end_time desc;
