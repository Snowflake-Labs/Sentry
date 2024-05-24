SELECT
    *
FROM
    snowflake.account_usage.replication_usage_history
WHERE
    TO_DATE(START_TIME) BETWEEN
        dateadd(d, -7, current_date) AND current_date;
