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
CREATE OR REPLACE PROCEDURE SENTRY_may30_ttps_guidance_anomalous_application_access ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(SELECT
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
    1 DESC

);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_may30_ttps_guidance_factor_breakdown ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select client_ip, user_name, reported_client_type, first_authentication_factor, count(*)
from snowflake.account_usage.login_history
group by client_ip, user_name, reported_client_type, first_authentication_factor
order by count(*) desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_may30_ttps_guidance_ip_logins ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(--
SELECT
    *
FROM
    snowflake.account_usage.login_history
WHERE
    client_ip IN (
'102.165.16.161',
'104.129.24.124',
'104.223.91.28',
'146.70.117.210',
'146.70.117.56',
'146.70.124.216',
'146.70.165.227',
'146.70.166.176',
'146.70.171.112',
'146.70.171.99',
'154.47.30.137',
'154.47.30.150',
'169.150.201.25',
'169.150.203.22',
'173.44.63.112',
'176.123.6.193',
'184.147.100.29',
'185.156.46.163',
'185.213.155.241',
'185.248.85.14',
'185.248.85.59',
'192.252.212.60',
'193.32.126.233',
'194.230.144.126',
'198.44.129.82',
'198.44.136.56',
'198.44.136.82',
'198.54.130.153',
'198.54.131.152',
'198.54.135.67',
'198.54.135.99',
'204.152.216.105',
'206.217.205.49',
'37.19.210.21',
'37.19.210.34',
'45.134.142.200',
'45.86.221.146',
'66.115.189.247',
'66.63.167.147',
'87.249.134.11',
'93.115.0.49',
'96.44.191.140'
    )
ORDER BY
event_timestamp
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_may30_ttps_guidance_ips_with_factor ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(-- NOTE: IP list is sorted
select event_timestamp, event_type, user_name, client_ip, reported_client_type, first_authentication_factor, second_authentication_factor, is_success
from snowflake.account_usage.login_history
where first_authentication_factor='PASSWORD'
and client_ip in (
    '104.129.24.124',
    '104.223.91.28',
    '104.223.91.28',
    '146.70.117.210',
    '146.70.117.210',
    '146.70.117.210',
    '146.70.117.210',
    '146.70.117.56',
    '146.70.124.216',
    '146.70.165.227',
    '146.70.166.176',
    '146.70.171.112',
    '146.70.171.99',
    '154.47.30.137',
    '154.47.30.150',
    '169.150.201.25',
    '169.150.203.22',
    '169.150.203.22',
    '173.44.63.112',
    '176.123.6.193',
    '184.147.100.29',
    '185.156.46.163',
    '185.213.155.241',
    '192.252.212.60',
    '193.32.126.233',
    '193.32.126.233',
    '194.230.144.126',
    '198.44.129.82',
    '198.44.136.56',
    '198.44.136.82',
    '198.54.130.153',
    '198.54.130.153',
    '198.54.130.153',
    '198.54.135.67',
    '198.54.135.99',
    '198.54.135.99',
    '204.152.216.105',
    '206.217.205.49',
    '206.217.206.108',
    '37.19.210.21',
    '37.19.210.34',
    '45.134.142.200',
    '45.134.142.200',
    '45.134.142.200',
    '45.86.221.146',
    '45.86.221.146',
    '45.86.221.146',
    '66.115.189.247',
    '66.115.189.247',
    '66.63.167.147',
    '87.249.134.11',
    '93.115.0.49',
    '93.21.79.57',
    '93.21.79.57',
    '96.44.191.140'
)
order by event_timestamp desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_may30_ttps_guidance_query_history ()
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
ORDER BY end_time desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_may30_ttps_guidance_static_creds ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select name, has_password, password_last_set_time, disabled, ext_authn_duo
from snowflake.account_usage.users
where has_password = 'true'
and disabled = 'false'
and ext_authn_duo = 'false'
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
CREATE OR REPLACE PROCEDURE SENTRY_sharing_access_count_by_column ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select
  los.value:"objectDomain"::string as object_type,
  los.value:"objectName"::string as object_name,
  cols.value:"columnName"::string as column_name,
  count(distinct lah.query_token) as n_queries,
  count(distinct lah.consumer_account_locator) as n_distinct_consumer_accounts
from SNOWFLAKE.DATA_SHARING_USAGE.LISTING_ACCESS_HISTORY as lah
join lateral flatten(input=>lah.listing_objects_accessed) as los
join lateral flatten(input=>los.value, path=>'columns') as cols
where true
  and los.value:"objectDomain"::string in ('Table', 'View')
  and query_date between '2024-03-21' and '2024-03-30'
  and los.value:"objectName"::string = 'db1.schema1.sec_view1'
  and lah.consumer_account_locator = 'BATC4932'
group by 1,2,3
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_sharing_access_over_time_by_consumer ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select
  lah.exchange_name,
  lah.listing_global_name,
  lah.share_name,
  los.value:"objectName"::string as object_name,
  coalesce(los.value:"objectDomain"::string, los.value:"objectDomain"::string) as object_type,
  consumer_account_locator,
  count(distinct lah.query_token) as n_queries
from SNOWFLAKE.DATA_SHARING_USAGE.LISTING_ACCESS_HISTORY as lah
join lateral flatten(input=>lah.listing_objects_accessed) as los
where true
  and query_date between '2024-03-21' and '2024-03-30'
group by 1,2,3,4,5,6
order by 1,2,3,4,5,6
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_sharing_listing_usage ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(SELECT
  listing_name,
  listing_display_name,
  event_date,
  event_type,
  SUM(1) AS count_gets_requests
FROM snowflake.data_sharing_usage.listing_events_daily
GROUP BY 1,2,3,4
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_sharing_listings_alter ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select
    user_name || ' altered a listing at ' || end_time as Description, execution_status, query_text as Statement
from
    SNOWFLAKE.ACCOUNT_USAGE.query_history
where
    query_type = 'ALTER'
    and query_text ilike '%alter%listing%'
order by
    end_time desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_sharing_reader_creation_monitor ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select
    user_name || ' tried to create a managed account at ' || end_time as Description, execution_status, query_text as Statement
from
    SNOWFLAKE.ACCOUNT_USAGE.query_history
where
    query_type = 'CREATE'
    and query_text ilike '%managed%account%'
order by
    end_time desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_sharing_replication_history ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(SELECT
    *
FROM
    snowflake.account_usage.replication_usage_history
WHERE
    TO_DATE(START_TIME) BETWEEN
        dateadd(d, -7, current_date) AND current_date
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_sharing_share_alter ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(select
    user_name || ' altered a share at ' || end_time as Description, execution_status, query_text as Statement
from
    SNOWFLAKE.ACCOUNT_USAGE.query_history
where
    query_type = 'ALTER'
    and query_text ilike '%alter%share%'
order by
    end_time desc
);
RETURN TABLE(res);
END
$$;
CREATE OR REPLACE PROCEDURE SENTRY_sharing_table_joins_by_consumer ()
RETURNS TABLE()
LANGUAGE SQL
AS
$$
DECLARE
res RESULTSET;
BEGIN
res :=(with
accesses as (
  select distinct
    los.value:"objectDomain"::string as object_type,
    los.value:"objectName"::string as object_name,
    lah.query_token,
    lah.consumer_account_locator
  from SNOWFLAKE.DATA_SHARING_USAGE.LISTING_ACCESS_HISTORY as lah
  join lateral flatten(input=>lah.listing_objects_accessed) as los
  where true
    and los.value:"objectDomain"::string in ('Table', 'View')
    and query_date between '2024-03-21' and '2024-03-30'
)
select
  a1.object_name as object_name_1,
  a2.object_name as object_name_2,
  a1.consumer_account_locator as consumer_account_locator,
  count(distinct a1.query_token) as n_queries
from accesses as a1
join accesses as a2
  on a1.query_token = a2.query_token
  and a1.object_name < a2.object_name
group by 1,2,3

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
