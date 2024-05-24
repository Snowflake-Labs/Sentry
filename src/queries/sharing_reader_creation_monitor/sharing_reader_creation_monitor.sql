select
    user_name || ' tried to create a managed account at ' || end_time as Description, execution_status, query_text as Statement
from
    SNOWFLAKE.ACCOUNT_USAGE.query_history
where
    query_type = 'CREATE'
    and query_text ilike '%managed%account%'
order by
    end_time desc;
