SELECT
    user_name,
    role_name,
    database_name,
    schema_name,
    object_name,
    object_type,
    error_code,
    error_message,
    COUNT(*) as failure_count,
    MIN(start_time) as first_attempt,
    MAX(start_time) as last_attempt,
    user_name || ' had ' || COUNT(*) || ' failed authorization attempts on ' || 
        object_type || ' ' || COALESCE(object_name, 'UNKNOWN') as Description
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE execution_status = 'FAIL'
    AND (error_message ILIKE '%authorization%' 
         OR error_message ILIKE '%insufficient privileges%'
         OR error_message ILIKE '%access denied%')
    AND start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY user_name, role_name, database_name, schema_name, object_name, object_type, error_code, error_message
HAVING COUNT(*) >= 3
ORDER BY failure_count DESC, last_attempt DESC;

