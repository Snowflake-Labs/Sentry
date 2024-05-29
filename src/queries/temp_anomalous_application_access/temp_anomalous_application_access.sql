SELECT
    COUNT(*) AS client_app_count,
    PARSE_JSON(client_environment) :APPLICATION :: STRING AS client_application,
    PARSE_JSON(client_environment) :OS :: STRING AS client_os,
    PARSE_JSON(client_environment) :OS_VERSION :: STRING AS client_os_version
FROM
    snowflake.account_usage.sessions sessions
WHERE
    1 = 1
    AND sessions.created_on >= '2024-04-01'
GROUP BY
    ALL
ORDER BY
    1 ASC;

