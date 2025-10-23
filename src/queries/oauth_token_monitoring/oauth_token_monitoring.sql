SELECT
    user_name,
    role_name,
    query_type,
    start_time,
    execution_status,
    CASE
        WHEN query_text ILIKE '%CREATE%SECURITY%INTEGRATION%' THEN 'OAuth Integration Created'
        WHEN query_text ILIKE '%ALTER%SECURITY%INTEGRATION%' THEN 'OAuth Integration Modified'
        WHEN query_text ILIKE '%DROP%SECURITY%INTEGRATION%' THEN 'OAuth Integration Dropped'
        ELSE 'OAuth Activity'
    END as activity_type,
    query_text,
    user_name || ' performed ' || query_type || ' on OAuth integration at ' || start_time as Description
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE (query_text ILIKE '%security integration%' AND query_text ILIKE '%oauth%')
    AND start_time >= DATEADD(day, -90, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

