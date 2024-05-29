SELECT
  query_text,
  user_name,
  role_name,
  end_time
FROM snowflake.account_usage.query_history
  WHERE execution_status = 'SUCCESS'
    AND query_type NOT in ('SELECT')
    --AND user_name= '<USER>'
    AND (query_text ILIKE '%create role%'
        OR query_text ILIKE '%manage grants%'
        OR query_text ILIKE '%create integration%'
        OR query_text ILIKE '%alter integration%'
        OR query_text ILIKE '%create share%'
        OR query_text ILIKE '%create account%'
        OR query_text ILIKE '%monitor usage%'
        OR query_text ILIKE '%ownership%'
        OR query_text ILIKE '%drop table%'
        OR query_text ILIKE '%drop database%'
        OR query_text ILIKE '%create stage%'
        OR query_text ILIKE '%drop stage%'
        OR query_text ILIKE '%alter stage%'
        OR query_text ILIKE '%create user%'
        OR query_text ILIKE '%alter user%'
        OR query_text ILIKE '%drop user%'
        OR query_text ILIKE '%create_network_policy%'
        OR query_text ILIKE '%alter_network_policy%'
        OR query_text ILIKE '%drop_network_policy%'
        OR query_text ILIKE '%copy%'
        )
ORDER BY end_time desc;
