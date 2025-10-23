WITH service_accounts AS (
    SELECT name
    FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
    WHERE (name ILIKE '%svc%' OR name ILIKE '%service%' OR name ILIKE '%app%')
        AND deleted_on IS NULL
),
hourly_activity AS (
    SELECT
        qh.user_name,
        DATE_TRUNC('hour', qh.start_time) as activity_hour,
        COUNT(DISTINCT qh.query_id) as query_count,
        COUNT(DISTINCT qh.session_id) as session_count,
        COUNT(DISTINCT lh.client_ip) as distinct_ips
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
    LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY lh
        ON qh.user_name = lh.user_name
        AND DATE_TRUNC('hour', qh.start_time) = DATE_TRUNC('hour', lh.event_timestamp)
    WHERE qh.user_name IN (SELECT name FROM service_accounts)
        AND qh.start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    GROUP BY qh.user_name, DATE_TRUNC('hour', qh.start_time)
)
SELECT
    user_name,
    activity_hour,
    query_count,
    session_count,
    distinct_ips,
    user_name || ' had ' || query_count || ' queries from ' || distinct_ips || 
        ' IPs during hour ' || activity_hour as Description
FROM hourly_activity
WHERE distinct_ips > 3 OR query_count > 1000
ORDER BY activity_hour DESC, query_count DESC;

