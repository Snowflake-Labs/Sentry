CREATE OR REPLACE PROCEDURE SENTRY_accountadmin_grants ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select
    user_name || ' granted the ' || role_name || ' role on ' || end_time as Description, query_text as Statement
from
    SNOWFLAKE.ACCOUNT_USAGE.query_history
where
    execution_status = 'SUCCESS'
    and query_type = 'GRANT'
    and query_text ilike '%grant%accountadmin%to%'
order by
    end_time desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_accountadmin_no_mfa ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select u.name,
timediff(days, last_success_login, current_timestamp()) || ' days ago' last_login ,
timediff(days, password_last_set_time,current_timestamp(6)) || ' days ago' password_age
from SNOWFLAKE.ACCOUNT_USAGE.users u
join SNOWFLAKE.ACCOUNT_USAGE.grants_to_users g on grantee_name = name and role = 'ACCOUNTADMIN' and g.deleted_on is null
where ext_authn_duo = false and u.deleted_on is null and has_password = true
order by last_success_login desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_auth_by_method ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select
   first_authentication_factor || ' ' ||nvl(second_authentication_factor, '') as authentication_method
   , count(*)
    from SNOWFLAKE.ACCOUNT_USAGE.login_history
    where is_success = 'YES'
    and user_name != 'WORKSHEETS_APP_USER'
    group by authentication_method
    order by count(*) desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_auth_bypassing ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(SELECT
 l.user_name,
 first_authentication_factor,
 second_authentication_factor,
 count(*) as Num_of_events
FROM SNOWFLAKE.ACCOUNT_USAGE.login_history as l
JOIN SNOWFLAKE.ACCOUNT_USAGE.users u on l.user_name = u.name and l.user_name ilike '%svc' and has_rsa_public_key = 'true'
WHERE is_success = 'YES'
AND first_authentication_factor != 'RSA_KEYPAIR'
GROUP BY l.user_name, first_authentication_factor, second_authentication_factor
ORDER BY count(*) desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_avg_number_of_role_grants_per_user ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(with role_grants_per_user (user, role_count) as (
select grantee_name as user, count(*) role_count from SNOWFLAKE.ACCOUNT_USAGE.grants_to_users where deleted_on is null group by grantee_name order by role_count desc)
select round(avg(role_count),1) from role_grants_per_user
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_bloated_roles ()
RETURNS TABLE(ROLE String, NUM_OF_PRIVS Integer)
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(--Role Hierarchy
with role_hier as (
    --Extract all Roles
    select
        grantee_name,
        name
    from
        SNOWFLAKE.ACCOUNT_USAGE.grants_to_roles
    where
        granted_on = 'ROLE'
        and privilege = 'USAGE'
        and deleted_on is null
    union all
        --Adding in dummy records for "root" roles
    select
        'root',
        r.name
    from
        SNOWFLAKE.ACCOUNT_USAGE.roles r
    where
        deleted_on is null
        and not exists (
            select
                1
            from
                SNOWFLAKE.ACCOUNT_USAGE.grants_to_roles gtr
            where
                gtr.granted_on = 'ROLE'
                and gtr.privilege = 'USAGE'
                and gtr.name = r.name
                and deleted_on is null
        )
) --CONNECT BY to create the polyarchy and SYS_CONNECT_BY_PATH to flatten it
,
role_path_pre as(
    select
        name,
        level,
        sys_connect_by_path(name, ' -> ') as path
    from
        role_hier connect by grantee_name = prior name start with grantee_name = 'root'
    order by
        path
) --Removing leading delimiter separately since there is some issue with how it interacted with sys_connect_by_path
,
role_path as (
    select
        name,
        level,
        substr(path, len(' -> ')) as path
    from
        role_path_pre
) --Joining in privileges from GRANT_TO_ROLES
,
role_path_privs as (
    select
        path,
        rp.name as role_name,
        privs.privilege,
        granted_on,
        privs.name as priv_name,
        'Role ' || path || ' has ' || privilege || ' on ' || granted_on || ' ' || privs.name as Description
    from
        role_path rp
        left join SNOWFLAKE.ACCOUNT_USAGE.grants_to_roles privs on rp.name = privs.grantee_name
        and privs.granted_on != 'ROLE'
        and deleted_on is null
    order by
        path
) --Aggregate total number of priv's per role, including hierarchy
,
role_path_privs_agg as (
    select
        trim(split(path, ' -> ') [0]) role,
        count(*) num_of_privs
    from
        role_path_privs
    group by
        trim(split(path, ' -> ') [0])
    order by
        count(*) desc
)
select * from role_path_privs_agg order by num_of_privs desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_default_role_check ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select role, grantee_name, default_role
from SNOWFLAKE.ACCOUNT_USAGE."GRANTS_TO_USERS" join "SNOWFLAKE"."ACCOUNT_USAGE"."USERS"
on users.name = grants_to_users.grantee_name
where role = 'ACCOUNTADMIN'
and grants_to_users.deleted_on is null
and users.deleted_on is null
order by grantee_name
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_grants_to_public ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select user_name, role_name, query_text, end_time
from SNOWFLAKE.ACCOUNT_USAGE.query_history where execution_status = 'SUCCESS'
and query_type = 'GRANT' and
query_text ilike '%to%public%'
order by end_time desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_grants_to_unmanaged_schemas_outside_schema_owner ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select table_catalog,
        table_schema,
        schema_owner,
        privilege,
        granted_by,
        granted_on,
        name,
        granted_to,
        grantee_name,
        grant_option
   from SNOWFLAKE.ACCOUNT_USAGE.grants_to_roles gtr
   join SNOWFLAKE.ACCOUNT_USAGE.schemata s
     on s.catalog_name = gtr.table_catalog
    and s.schema_name = gtr.table_schema
  where deleted_on is null
    and deleted is null
    and granted_by not in ('ACCOUNTADMIN', 'SECURITYADMIN') //add other roles with MANAGE GRANTS if applicable
    and is_managed_access = 'NO'
    and schema_owner <> granted_by
  order by
        table_catalog,
        table_schema
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_least_used_role_grants ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(with least_used_roles (user_name, role_name, last_used, times_used) as
(select user_name, role_name, max(end_time), count(*) from SNOWFLAKE.ACCOUNT_USAGE.query_history group by user_name, role_name order by user_name, role_name)
select grantee_name,
role,
nvl(last_used, (select min(start_time) from SNOWFLAKE.ACCOUNT_USAGE.query_history)) last_used,
nvl(times_used, 0) times_used, datediff(day, created_on, current_timestamp()) || ' days ago' age
from SNOWFLAKE.ACCOUNT_USAGE.grants_to_users
left join least_used_roles on user_name = grantee_name and role = role_name
where deleted_on is null order by last_used, times_used, age desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_most_dangerous_person ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(with role_hier as (
    --Extract all Roles
    select
        grantee_name,
        name
    from
        SNOWFLAKE.ACCOUNT_USAGE.grants_to_roles
    where
        granted_on = 'ROLE'
        and privilege = 'USAGE'
        and deleted_on is null
    union all
        --Adding in dummy records for "root" roles
    select
        'root',
        r.name
    from
        SNOWFLAKE.ACCOUNT_USAGE.roles r
    where
        deleted_on is null
        and not exists (
            select
                1
            from
                SNOWFLAKE.ACCOUNT_USAGE.grants_to_roles gtr
            where
                gtr.granted_on = 'ROLE'
                and gtr.privilege = 'USAGE'
                and gtr.name = r.name
                and deleted_on is null
        )
) --CONNECT BY to create the polyarchy and SYS_CONNECT_BY_PATH to flatten it
,
role_path_pre as(
    select
        name,
        level,
        sys_connect_by_path(name, ' -> ') as path
    from
        role_hier connect by grantee_name = prior name start with grantee_name = 'root'
    order by
        path
) --Removing leading delimiter separately since there is some issue with how it interacted with sys_connect_by_path
,
role_path as (
    select
        name,
        level,
        substr(path, len(' -> ')) as path
    from
        role_path_pre
) --Joining in privileges from GRANT_TO_ROLES
,
role_path_privs as (
    select
        path,
        rp.name as role_name,
        privs.privilege,
        granted_on,
        privs.name as priv_name,
        'Role ' || path || ' has ' || privilege || ' on ' || granted_on || ' ' || privs.name as Description
    from
        role_path rp
        left join SNOWFLAKE.ACCOUNT_USAGE.grants_to_roles privs on rp.name = privs.grantee_name
        and privs.granted_on != 'ROLE'
        and deleted_on is null
    order by
        path
) --Aggregate total number of priv's per role, including hierarchy
,
role_path_privs_agg as (
    select
        trim(split(path, ' -> ') [0]) role,
        count(*) num_of_privs
    from
        role_path_privs
    group by
        trim(split(path, ' -> ') [0])
    order by
        count(*) desc
) --Most Dangerous Man - final query
select
    grantee_name as user,
    count(a.role) num_of_roles,
    sum(num_of_privs) num_of_privs
from
    SNOWFLAKE.ACCOUNT_USAGE.grants_to_users u
    join role_path_privs_agg a on a.role = u.role
where
    u.deleted_on is null
group by
    user
order by
    num_of_privs desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_network_policy_changes ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select user_name || ' made the following Network Policy change on ' || end_time || ' [' ||  query_text || ']' as Events
   from SNOWFLAKE.ACCOUNT_USAGE.query_history where execution_status = 'SUCCESS'
   and query_type in ('CREATE_NETWORK_POLICY', 'ALTER_NETWORK_POLICY', 'DROP_NETWORK_POLICY')
   or (query_text ilike '% set network_policy%' or
       query_text ilike '% unset network_policy%')
       and query_type != 'SELECT' and query_type != 'UNKNOWN'
   order by end_time desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_num_failures ()
RETURNS TABLE(USER_NAME String, ERROR_MESSAGE String, NUM_OF_FAILURES Integer)
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select
    user_name,
    error_message,
    count(*) num_of_failures
from
    SNOWFLAKE.ACCOUNT_USAGE.login_history
where
    is_success = 'NO'
group by
    user_name,
    error_message
order by
    num_of_failures desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_privileged_object_changes_by_user ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(SELECT
    query_text,
    user_name,
    role_name,
    end_time
  FROM SNOWFLAKE.ACCOUNT_USAGE.query_history
    WHERE execution_status = 'SUCCESS'
      AND query_type NOT in ('SELECT')
      AND (query_text ILIKE '%create role%'
          OR query_text ILIKE '%manage grants%'
          OR query_text ILIKE '%create integration%'
          OR query_text ILIKE '%create share%'
          OR query_text ILIKE '%create account%'
          OR query_text ILIKE '%monitor usage%'
          OR query_text ILIKE '%ownership%'
          OR query_text ILIKE '%drop table%'
          OR query_text ILIKE '%drop database%'
          OR query_text ILIKE '%create stage%'
          OR query_text ILIKE '%drop stage%'
          OR query_text ILIKE '%alter stage%'
          )
  ORDER BY end_time desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_scim_token_lifecycle ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select
    user_name as by_whom,
    datediff('day', start_time, current_timestamp()) || ' days ago' as created_on,
    ADD_MONTHS(start_time, 6) as expires_on,
    datediff(
        'day',
        current_timestamp(),
        ADD_MONTHS(end_time, 6)
    ) as expires_in_days
from
    SNOWFLAKE.ACCOUNT_USAGE.query_history
where
    execution_status = 'SUCCESS'
    and query_text ilike 'select%SYSTEM$GENERATE_SCIM_ACCESS_TOKEN%'
    and query_text not ilike 'select%where%SYSTEM$GENERATE_SCIM_ACCESS_TOKEN%'
order by
    expires_in_days
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_stale_users ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select name, datediff("day", nvl(last_success_login, created_on), current_timestamp()) || ' days ago' Last_Login from SNOWFLAKE.ACCOUNT_USAGE.users
where deleted_on is null
order by datediff("day", nvl(last_success_login, created_on), current_timestamp()) desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_user_role_ratio ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select
round(count(*) / (select count(*) from SNOWFLAKE.ACCOUNT_USAGE.roles),1) as ratio
from SNOWFLAKE.ACCOUNT_USAGE.users
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_users_by_oldest_passwords ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select name, datediff('day', password_last_set_time, current_timestamp()) || ' days ago' as password_last_changed from SNOWFLAKE.ACCOUNT_USAGE.users
where deleted_on is null and
password_last_set_time is not null
order by password_last_set_time
);
RETURN TABLE(res);
END
$$;
