SELECT
 l.user_name,
 first_authentication_factor,
 second_authentication_factor,
 count(*) as Num_of_events
FROM SNOWFLAKE.ACCOUNT_USAGE.login_history as l
JOIN SNOWFLAKE.ACCOUNT_USAGE.users u on l.user_name = u.name and l.user_name ilike '%svc' and has_rsa_public_key = 'true'
WHERE is_success = 'YES'
AND first_authentication_factor != 'RSA_KEYPAIR'
GROUP BY l.user_name, first_authentication_factor, second_authentication_factor
ORDER BY count(*) desc;
