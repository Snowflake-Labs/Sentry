select
round(count(*) / (select count(*) from SNOWFLAKE.ACCOUNT_USAGE.roles),1) as ratio
from SNOWFLAKE.ACCOUNT_USAGE.users;
