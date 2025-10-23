SELECT
    user_name,
    role_name,
    query_type,
    database_name,
    schema_name,
    error_code,
    error_message,
    start_time,
    LEFT(query_text, 200) as query_preview,
    user_name || ' failed ' || query_type || ' operation: ' || error_message as Description
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE execution_status = 'FAIL'
    AND query_type IN ('CREATE', 'ALTER', 'DROP', 'CREATE_TABLE', 'ALTER_TABLE', 
                       'DROP_TABLE', 'CREATE_DATABASE', 'DROP_DATABASE', 
                       'CREATE_SCHEMA', 'DROP_SCHEMA')
    AND start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

