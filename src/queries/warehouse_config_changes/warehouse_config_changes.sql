SELECT
    user_name,
    role_name,
    start_time,
    query_text,
    execution_status,
    user_name || ' modified warehouse configuration at ' || start_time || 
        ' [' || execution_status || ']' as Description
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_type IN ('CREATE_WAREHOUSE', 'ALTER_WAREHOUSE')
    AND (query_text ILIKE '%auto_suspend%' 
         OR query_text ILIKE '%auto_resume%'
         OR query_text ILIKE '%warehouse_size%')
    AND start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

