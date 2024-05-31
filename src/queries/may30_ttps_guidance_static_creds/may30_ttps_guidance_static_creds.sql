select name, has_password, password_last_set_time, disabled, ext_authn_duo
from snowflake.account_usage.users
where has_password = 'true'
and disabled = 'false'
and ext_authn_duo = 'false';
