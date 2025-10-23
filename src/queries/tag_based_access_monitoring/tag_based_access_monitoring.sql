WITH tagged_objects AS (
    SELECT DISTINCT
        object_database,
        object_schema,
        object_name,
        tag_name,
        tag_value
    FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES
    WHERE tag_name IN ('PII', 'SENSITIVE', 'CONFIDENTIAL', 'PHI', 'PCI')
        AND deleted_on IS NULL
)
SELECT
    qh.user_name,
    qh.role_name,
    qh.query_type,
    to.tag_name,
    to.tag_value,
    to.object_database || '.' || to.object_schema || '.' || to.object_name as full_object_name,
    qh.start_time,
    COUNT(*) as access_count,
    qh.user_name || ' accessed ' || to.tag_name || '=' || to.tag_value || 
        ' tagged object ' || COUNT(*) || ' times' as Description
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
JOIN tagged_objects to
    ON qh.database_name = to.object_database
    AND qh.schema_name = to.object_schema
WHERE qh.start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    AND qh.execution_status = 'SUCCESS'
GROUP BY qh.user_name, qh.role_name, qh.query_type, to.tag_name, to.tag_value, 
         to.object_database, to.object_schema, to.object_name, qh.start_time
ORDER BY qh.start_time DESC;

