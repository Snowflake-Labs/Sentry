SELECT
    user_name,
    role_name,
    query_type,
    database_name,
    schema_name,
    start_time,
    execution_status,
    query_text,
    user_name || ' executed ' || query_type || ' on ' || 
        COALESCE(database_name || '.' || schema_name, database_name, 'UNKNOWN') || 
        ' at ' || start_time || ' [' || execution_status || ']' as Description
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_type IN ('DROP_DATABASE', 'DROP_SCHEMA', 'DROP_TABLE', 'TRUNCATE_TABLE')
    AND start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

