WITH warehouse_daily_usage AS (
    SELECT
        warehouse_name,
        DATE(start_time) as usage_date,
        SUM(credits_used) as daily_credits,
        COUNT(DISTINCT query_id) as query_count,
        AVG(execution_time) as avg_execution_time
    FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
    WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
    GROUP BY warehouse_name, DATE(start_time)
),
warehouse_stats AS (
    SELECT
        warehouse_name,
        AVG(daily_credits) as avg_daily_credits,
        STDDEV(daily_credits) as stddev_credits
    FROM warehouse_daily_usage
    GROUP BY warehouse_name
)
SELECT
    wdu.warehouse_name,
    wdu.usage_date,
    wdu.daily_credits,
    ws.avg_daily_credits,
    ROUND((wdu.daily_credits - ws.avg_daily_credits) / NULLIF(ws.stddev_credits, 0), 2) as z_score,
    wdu.query_count,
    ROUND(wdu.avg_execution_time/1000, 2) as avg_execution_seconds
FROM warehouse_daily_usage wdu
JOIN warehouse_stats ws ON wdu.warehouse_name = ws.warehouse_name
WHERE ABS((wdu.daily_credits - ws.avg_daily_credits) / NULLIF(ws.stddev_credits, 0)) > 2
ORDER BY z_score DESC, wdu.usage_date DESC;

