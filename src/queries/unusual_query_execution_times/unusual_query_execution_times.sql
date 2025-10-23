WITH query_stats AS (
    SELECT
        user_name,
        warehouse_name,
        query_type,
        ROUND(AVG(execution_time)/1000, 2) as avg_execution_seconds,
        ROUND(STDDEV(execution_time)/1000, 2) as stddev_execution_seconds,
        COUNT(*) as query_count
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
    WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
        AND execution_status = 'SUCCESS'
        AND query_type != 'SELECT'
    GROUP BY user_name, warehouse_name, query_type
    HAVING COUNT(*) >= 10
)
SELECT
    qh.user_name,
    qh.role_name,
    qh.warehouse_name,
    qh.query_type,
    qh.query_id,
    ROUND(qh.execution_time/1000, 2) as execution_seconds,
    qs.avg_execution_seconds,
    ROUND((qh.execution_time/1000 - qs.avg_execution_seconds) / NULLIF(qs.stddev_execution_seconds, 0), 2) as z_score,
    qh.start_time,
    LEFT(qh.query_text, 100) as query_preview
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
JOIN query_stats qs 
    ON qh.user_name = qs.user_name 
    AND qh.warehouse_name = qs.warehouse_name 
    AND qh.query_type = qs.query_type
WHERE qh.execution_status = 'SUCCESS'
    AND qh.start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    AND ABS((qh.execution_time/1000 - qs.avg_execution_seconds) / NULLIF(qs.stddev_execution_seconds, 0)) > 3
ORDER BY z_score DESC;

