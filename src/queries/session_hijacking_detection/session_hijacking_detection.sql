WITH session_ips AS (
    SELECT
        user_name,
        session_id,
        client_ip,
        event_timestamp,
        reported_client_type,
        LAG(client_ip) OVER (PARTITION BY session_id ORDER BY event_timestamp) as prev_ip,
        LAG(event_timestamp) OVER (PARTITION BY session_id ORDER BY event_timestamp) as prev_timestamp
    FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
    WHERE event_timestamp >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        AND is_success = 'YES'
)
SELECT
    user_name,
    session_id,
    prev_ip as original_ip,
    client_ip as new_ip,
    prev_timestamp as original_login_time,
    event_timestamp as ip_change_time,
    DATEDIFF(minute, prev_timestamp, event_timestamp) as minutes_between_changes,
    reported_client_type,
    user_name || ' session ' || session_id || ' changed from IP ' || prev_ip || 
        ' to ' || client_ip || ' after ' || DATEDIFF(minute, prev_timestamp, event_timestamp) || 
        ' minutes' as Description
FROM session_ips
WHERE client_ip != prev_ip
    AND prev_ip IS NOT NULL
    AND DATEDIFF(minute, prev_timestamp, event_timestamp) < 60
ORDER BY event_timestamp DESC;

