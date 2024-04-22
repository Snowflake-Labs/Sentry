select user_name || ' made the following Network Policy change on ' || end_time || ' [' ||  query_text || ']' as Events
   from SNOWFLAKE.ACCOUNT_USAGE.query_history where execution_status = 'SUCCESS'
   and query_type in ('CREATE_NETWORK_POLICY', 'ALTER_NETWORK_POLICY', 'DROP_NETWORK_POLICY')
   or (query_text ilike '% set network_policy%' or
       query_text ilike '% unset network_policy%')
       and query_type != 'SELECT' and query_type != 'UNKNOWN'
   order by end_time desc;
