WITH user_login_patterns AS (
    SELECT
        user_name,
        EXTRACT(HOUR FROM event_timestamp) as login_hour,
        COUNT(*) as login_count
    FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
    WHERE event_timestamp >= DATEADD(day, -30, CURRENT_TIMESTAMP())
        AND is_success = 'YES'
    GROUP BY user_name, EXTRACT(HOUR FROM event_timestamp)
),
typical_hours AS (
    SELECT
        user_name,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY login_hour) as q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY login_hour) as q3
    FROM user_login_patterns
    GROUP BY user_name
)
SELECT
    lh.user_name,
    lh.event_timestamp,
    EXTRACT(HOUR FROM lh.event_timestamp) as login_hour,
    lh.client_ip,
    lh.reported_client_type,
    th.q1 as typical_start_hour,
    th.q3 as typical_end_hour,
    lh.user_name || ' logged in at unusual hour ' || EXTRACT(HOUR FROM lh.event_timestamp) || 
        ':00 (typical hours: ' || th.q1 || '-' || th.q3 || ') from IP ' || lh.client_ip as Description
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY lh
JOIN typical_hours th ON lh.user_name = th.user_name
WHERE lh.is_success = 'YES'
    AND lh.event_timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    AND (EXTRACT(HOUR FROM lh.event_timestamp) < th.q1 - 3 
         OR EXTRACT(HOUR FROM lh.event_timestamp) > th.q3 + 3)
ORDER BY lh.event_timestamp DESC;

