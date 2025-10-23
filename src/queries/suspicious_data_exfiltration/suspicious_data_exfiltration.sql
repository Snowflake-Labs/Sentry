WITH data_transfer_stats AS (
    SELECT
        user_name,
        role_name,
        DATE(start_time) as query_date,
        COUNT(*) as export_count,
        SUM(bytes_scanned) as total_bytes_scanned,
        SUM(bytes_written_to_result) as total_bytes_exported,
        SUM(rows_produced) as total_rows_exported
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
    WHERE execution_status = 'SUCCESS'
        AND (
            query_type IN ('COPY', 'UNLOAD')
            OR query_text ILIKE '%GET%@%'
            OR query_text ILIKE '%COPY INTO @%'
            OR (query_text ILIKE '%SELECT%' AND bytes_written_to_result > 100000000)
        )
        AND start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    GROUP BY user_name, role_name, DATE(start_time)
)
SELECT
    user_name,
    role_name,
    query_date,
    export_count,
    ROUND(total_bytes_scanned / 1024 / 1024 / 1024, 2) as gb_scanned,
    ROUND(total_bytes_exported / 1024 / 1024 / 1024, 2) as gb_exported,
    total_rows_exported,
    user_name || ' exported ' || ROUND(total_bytes_exported / 1024 / 1024 / 1024, 2) || 
        ' GB across ' || export_count || ' queries on ' || query_date as Description
FROM data_transfer_stats
WHERE total_bytes_exported > 1073741824
ORDER BY total_bytes_exported DESC, query_date DESC;

