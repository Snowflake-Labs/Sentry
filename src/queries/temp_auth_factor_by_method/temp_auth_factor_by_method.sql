select
first_authentication_factor || ' ' ||nvl(second_authentication_factor, '') as authentication_method
, count(*)
from snowflake.account_usage.login_history
where is_success = 'YES'
group by authentication_method
order by count(*) desc;
