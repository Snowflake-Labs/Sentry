SELECT
    qh.user_name,
    qh.role_name,
    qh.query_type,
    qh.query_text,
    qh.start_time,
    qh.execution_status,
    user_name || ' performed ' || query_type || ' on external stage at ' || start_time as Description
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
WHERE execution_status = 'SUCCESS'
    AND (
        (query_type IN ('CREATE_STAGE', 'ALTER_STAGE', 'DROP_STAGE') 
         AND (query_text ILIKE '%s3://%' 
              OR query_text ILIKE '%azure://%' 
              OR query_text ILIKE '%gcs://%'))
        OR (query_type = 'COPY' AND query_text ILIKE '%@%')
    )
    AND start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

