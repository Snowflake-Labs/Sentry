select client_ip, user_name, reported_client_type, first_authentication_factor, count(*)
from snowflake.account_usage.login_history
group by client_ip, user_name, reported_client_type, first_authentication_factor
order by count(*) desc;
