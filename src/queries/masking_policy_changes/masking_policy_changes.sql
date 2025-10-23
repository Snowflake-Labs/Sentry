SELECT
    user_name,
    role_name,
    query_type,
    start_time,
    execution_status,
    query_text,
    user_name || ' performed ' || query_type || ' on masking policy at ' || 
        start_time || ' [' || execution_status || ']' as Description
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE (query_text ILIKE '%masking policy%' OR query_text ILIKE '%masking_policy%')
    AND query_type IN ('CREATE', 'ALTER', 'DROP', 'SET', 'UNSET')
    AND start_time >= DATEADD(day, -90, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

