# Queries
<!-- NOTE: This is generated through mdsh, do not edit by hand -->

<!-- `> nix run .#mkSprocDocs | sed 's;^#;##;'` -->

<!-- BEGIN mdsh -->
## ACCOUNTADMIN Grants

All existing and especially new AA grants should be few, rare and
well-justified.

```sql
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
$$
```

## ACCOUNTADMINs that do not use MFA

```sql
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
$$
```

## Breakdown by Method

Recommendation: enforce modern authentication via SAML, Key Pair, OAUTH.

```sql
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
$$
```

## Key Pair Bypass (Password)

**Note:** this query would need to be adjusted to reflect the service user
naming convention.

```sql
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
$$
```

## Average Number of Role Grants per User (~5-10)

```sql
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
$$
```

## Bloated roles

Roles with largest amount of effective privileges

```sql
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
$$
```

## Default Role is ACCOUNTADMIN

```sql
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
$$
```

## Grants to PUBLIC role

```sql
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
$$
```

## Grants to unmanaged schemas outside schema owner

```sql
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
$$
```

## Least Used Role Grants

```sql
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
$$
```

## Anomalous Application Access

```sql
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
$$
```

## Aggregate of client IPs leveraged at authentication for service discovery

```sql
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
$$
```

## Monitored IPs logins

Current IOC's are tied to the listed IP's, often leveraging a JDBC driver, and
authenticating via a Password stored locally in Snowflake.

```sql
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
'103.108.229.67',
'103.108.231.51',
'103.108.231.67',
'103.125.233.19',
'103.136.147.130',
'103.136.147.4',
'103.214.20.131',
'103.216.220.19',
'103.216.220.35',
'103.75.11.51',
'103.75.11.67',
'104.129.24.115',
'104.129.24.124',
'104.129.41.195',
'104.129.57.67',
'104.223.91.19',
'104.223.91.28',
'107.150.22.3',
'129.227.46.131',
'129.227.46.163',
'138.199.15.147',
'138.199.15.163',
'138.199.21.227',
'138.199.21.240',
'138.199.34.144',
'138.199.43.66',
'138.199.43.79',
'138.199.43.92',
'138.199.6.195',
'138.199.6.208',
'138.199.6.221',
'138.199.60.16',
'138.199.60.29',
'138.199.60.3',
'141.98.252.190',
'142.147.89.226',
'143.244.47.66',
'143.244.47.79',
'143.244.47.92',
'146.70.117.163',
'146.70.117.210',
'146.70.117.35',
'146.70.117.56',
'146.70.119.24',
'146.70.119.35',
'146.70.124.131',
'146.70.124.216',
'146.70.128.195',
'146.70.128.227',
'146.70.129.131',
'146.70.129.99',
'146.70.132.195',
'146.70.132.227',
'146.70.133.3',
'146.70.133.99',
'146.70.134.3',
'146.70.138.195',
'146.70.144.35',
'146.70.165.227',
'146.70.165.3',
'146.70.166.131',
'146.70.166.176',
'146.70.168.195',
'146.70.168.67',
'146.70.171.112',
'146.70.171.131',
'146.70.171.67',
'146.70.171.99',
'146.70.173.131',
'146.70.173.195',
'146.70.184.3',
'146.70.184.67',
'146.70.185.3',
'146.70.187.67',
'146.70.188.131',
'146.70.196.195',
'146.70.197.131',
'146.70.197.195',
'146.70.198.195',
'146.70.199.131',
'146.70.199.195',
'146.70.200.3',
'146.70.211.67',
'146.70.224.3',
'146.70.225.3',
'146.70.225.67',
'149.102.240.67',
'149.102.240.80',
'149.102.246.16',
'149.102.246.3',
'149.22.81.195',
'149.22.81.208',
'149.40.50.113',
'149.88.104.16',
'149.88.20.194',
'149.88.20.207',
'149.88.22.130',
'149.88.22.143',
'149.88.22.156',
'149.88.22.169',
'154.47.16.35',
'154.47.16.48',
'154.47.29.3',
'154.47.30.131',
'154.47.30.137',
'154.47.30.144',
'154.47.30.150',
'156.59.50.195',
'156.59.50.227',
'162.33.177.32',
'169.150.196.16',
'169.150.196.29',
'169.150.196.3',
'169.150.198.67',
'169.150.201.25',
'169.150.201.29',
'169.150.201.3',
'169.150.203.16',
'169.150.203.22',
'169.150.203.29',
'169.150.223.208',
'169.150.227.198',
'169.150.227.211',
'169.150.227.223',
'173.205.85.35',
'173.205.93.3',
'173.44.63.112',
'173.44.63.67',
'176.123.10.35',
'176.123.3.132',
'176.123.6.193',
'176.123.7.143',
'176.220.186.152',
'178.249.209.163',
'178.249.209.176',
'178.249.211.67',
'178.249.211.80',
'178.249.211.93',
'178.249.214.16',
'178.249.214.3',
'178.255.149.166',
'179.43.189.67',
'184.147.100.29',
'185.156.46.144',
'185.156.46.157',
'185.156.46.163',
'185.188.61.196',
'185.188.61.226',
'185.201.188.34',
'185.201.188.4',
'185.204.1.178',
'185.204.1.179',
'185.213.155.241',
'185.248.85.14',
'185.248.85.19',
'185.248.85.34',
'185.248.85.49',
'185.248.85.59',
'185.254.75.14',
'185.65.134.191',
'188.241.176.195',
'192.252.212.60',
'193.138.7.138',
'193.138.7.158',
'193.19.207.196',
'193.19.207.226',
'193.32.126.233',
'194.110.115.3',
'194.110.115.35',
'194.127.167.108',
'194.127.167.88',
'194.127.199.3',
'194.127.199.32',
'194.230.144.126',
'194.230.144.50',
'194.230.145.67',
'194.230.145.76',
'194.230.147.127',
'194.230.148.99',
'194.230.158.107',
'194.230.158.178',
'194.230.160.237',
'194.230.160.5',
'194.36.25.34',
'194.36.25.4',
'194.36.25.49',
'195.160.223.23',
'198.44.129.35',
'198.44.129.67',
'198.44.129.82',
'198.44.129.99',
'198.44.136.195',
'198.44.136.35',
'198.44.136.56',
'198.44.136.67',
'198.44.136.82',
'198.44.136.99',
'198.44.140.195',
'198.54.130.131',
'198.54.130.147',
'198.54.130.153',
'198.54.130.99',
'198.54.131.131',
'198.54.131.152',
'198.54.131.163',
'198.54.133.131',
'198.54.133.163',
'198.54.134.131',
'198.54.134.99',
'198.54.135.131',
'198.54.135.35',
'198.54.135.67',
'198.54.135.99',
'199.116.118.194',
'199.116.118.210',
'199.116.118.233',
'204.152.216.105',
'204.152.216.115',
'204.152.216.99',
'206.217.205.118',
'206.217.205.119',
'206.217.205.125',
'206.217.205.126',
'206.217.205.49',
'206.217.206.108',
'206.217.206.28',
'206.217.206.48',
'206.217.206.68',
'206.217.206.88',
'209.54.101.131',
'31.170.22.16',
'31.171.154.51',
'37.19.200.131',
'37.19.200.144',
'37.19.200.157',
'37.19.210.2',
'37.19.210.21',
'37.19.210.28',
'37.19.210.34',
'37.19.221.144',
'37.19.221.157',
'37.19.221.170',
'38.240.225.37',
'38.240.225.69',
'43.225.189.132',
'43.225.189.163',
'45.134.140.131',
'45.134.140.144',
'45.134.142.194',
'45.134.142.200',
'45.134.142.207',
'45.134.142.220',
'45.134.212.80',
'45.134.212.93',
'45.134.213.195',
'45.134.79.68',
'45.134.79.98',
'45.155.91.99',
'45.86.221.146',
'46.19.136.227',
'5.47.87.202',
'66.115.189.160',
'66.115.189.190',
'66.115.189.200',
'66.115.189.210',
'66.115.189.247',
'66.63.167.147',
'66.63.167.163',
'66.63.167.195',
'68.235.44.195',
'68.235.44.3',
'68.235.44.35',
'69.4.234.116',
'69.4.234.118',
'69.4.234.119',
'69.4.234.120',
'69.4.234.122',
'69.4.234.124',
'69.4.234.125',
'79.127.217.35',
'79.127.217.44',
'79.127.217.48',
'79.127.222.195',
'79.127.222.208',
'87.249.134.11',
'87.249.134.15',
'87.249.134.2',
'87.249.134.28',
'92.60.40.210',
'92.60.40.225',
'93.115.0.49',
'96.44.189.99',
'96.44.191.131',
'96.44.191.140',
'96.44.191.147'
    )

ORDER BY
event_timestamp
);
RETURN TABLE(res);
END
$$
```

## Authentication patterns ordered by timestamp

```sql
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
'102.165.16.161',
'103.108.229.67',
'103.108.231.51',
'103.108.231.67',
'103.125.233.19',
'103.136.147.130',
'103.136.147.4',
'103.214.20.131',
'103.216.220.19',
'103.216.220.35',
'103.75.11.51',
'103.75.11.67',
'104.129.24.115',
'104.129.24.124',
'104.129.41.195',
'104.129.57.67',
'104.223.91.19',
'104.223.91.28',
'107.150.22.3',
'129.227.46.131',
'129.227.46.163',
'138.199.15.147',
'138.199.15.163',
'138.199.21.227',
'138.199.21.240',
'138.199.34.144',
'138.199.43.66',
'138.199.43.79',
'138.199.43.92',
'138.199.6.195',
'138.199.6.208',
'138.199.6.221',
'138.199.60.16',
'138.199.60.29',
'138.199.60.3',
'141.98.252.190',
'142.147.89.226',
'143.244.47.66',
'143.244.47.79',
'143.244.47.92',
'146.70.117.163',
'146.70.117.210',
'146.70.117.35',
'146.70.117.56',
'146.70.119.24',
'146.70.119.35',
'146.70.124.131',
'146.70.124.216',
'146.70.128.195',
'146.70.128.227',
'146.70.129.131',
'146.70.129.99',
'146.70.132.195',
'146.70.132.227',
'146.70.133.3',
'146.70.133.99',
'146.70.134.3',
'146.70.138.195',
'146.70.144.35',
'146.70.165.227',
'146.70.165.3',
'146.70.166.131',
'146.70.166.176',
'146.70.168.195',
'146.70.168.67',
'146.70.171.112',
'146.70.171.131',
'146.70.171.67',
'146.70.171.99',
'146.70.173.131',
'146.70.173.195',
'146.70.184.3',
'146.70.184.67',
'146.70.185.3',
'146.70.187.67',
'146.70.188.131',
'146.70.196.195',
'146.70.197.131',
'146.70.197.195',
'146.70.198.195',
'146.70.199.131',
'146.70.199.195',
'146.70.200.3',
'146.70.211.67',
'146.70.224.3',
'146.70.225.3',
'146.70.225.67',
'149.102.240.67',
'149.102.240.80',
'149.102.246.16',
'149.102.246.3',
'149.22.81.195',
'149.22.81.208',
'149.40.50.113',
'149.88.104.16',
'149.88.20.194',
'149.88.20.207',
'149.88.22.130',
'149.88.22.143',
'149.88.22.156',
'149.88.22.169',
'154.47.16.35',
'154.47.16.48',
'154.47.29.3',
'154.47.30.131',
'154.47.30.137',
'154.47.30.144',
'154.47.30.150',
'156.59.50.195',
'156.59.50.227',
'162.33.177.32',
'169.150.196.16',
'169.150.196.29',
'169.150.196.3',
'169.150.198.67',
'169.150.201.25',
'169.150.201.29',
'169.150.201.3',
'169.150.203.16',
'169.150.203.22',
'169.150.203.29',
'169.150.223.208',
'169.150.227.198',
'169.150.227.211',
'169.150.227.223',
'173.205.85.35',
'173.205.93.3',
'173.44.63.112',
'173.44.63.67',
'176.123.10.35',
'176.123.3.132',
'176.123.6.193',
'176.123.7.143',
'176.220.186.152',
'178.249.209.163',
'178.249.209.176',
'178.249.211.67',
'178.249.211.80',
'178.249.211.93',
'178.249.214.16',
'178.249.214.3',
'178.255.149.166',
'179.43.189.67',
'184.147.100.29',
'185.156.46.144',
'185.156.46.157',
'185.156.46.163',
'185.188.61.196',
'185.188.61.226',
'185.201.188.34',
'185.201.188.4',
'185.204.1.178',
'185.204.1.179',
'185.213.155.241',
'185.248.85.14',
'185.248.85.19',
'185.248.85.34',
'185.248.85.49',
'185.248.85.59',
'185.254.75.14',
'185.65.134.191',
'188.241.176.195',
'192.252.212.60',
'193.138.7.138',
'193.138.7.158',
'193.19.207.196',
'193.19.207.226',
'193.32.126.233',
'194.110.115.3',
'194.110.115.35',
'194.127.167.108',
'194.127.167.88',
'194.127.199.3',
'194.127.199.32',
'194.230.144.126',
'194.230.144.50',
'194.230.145.67',
'194.230.145.76',
'194.230.147.127',
'194.230.148.99',
'194.230.158.107',
'194.230.158.178',
'194.230.160.237',
'194.230.160.5',
'194.36.25.34',
'194.36.25.4',
'194.36.25.49',
'195.160.223.23',
'198.44.129.35',
'198.44.129.67',
'198.44.129.82',
'198.44.129.99',
'198.44.136.195',
'198.44.136.35',
'198.44.136.56',
'198.44.136.67',
'198.44.136.82',
'198.44.136.99',
'198.44.140.195',
'198.54.130.131',
'198.54.130.147',
'198.54.130.153',
'198.54.130.99',
'198.54.131.131',
'198.54.131.152',
'198.54.131.163',
'198.54.133.131',
'198.54.133.163',
'198.54.134.131',
'198.54.134.99',
'198.54.135.131',
'198.54.135.35',
'198.54.135.67',
'198.54.135.99',
'199.116.118.194',
'199.116.118.210',
'199.116.118.233',
'204.152.216.105',
'204.152.216.115',
'204.152.216.99',
'206.217.205.118',
'206.217.205.119',
'206.217.205.125',
'206.217.205.126',
'206.217.205.49',
'206.217.206.108',
'206.217.206.28',
'206.217.206.48',
'206.217.206.68',
'206.217.206.88',
'209.54.101.131',
'31.170.22.16',
'31.171.154.51',
'37.19.200.131',
'37.19.200.144',
'37.19.200.157',
'37.19.210.2',
'37.19.210.21',
'37.19.210.28',
'37.19.210.34',
'37.19.221.144',
'37.19.221.157',
'37.19.221.170',
'38.240.225.37',
'38.240.225.69',
'43.225.189.132',
'43.225.189.163',
'45.134.140.131',
'45.134.140.144',
'45.134.142.194',
'45.134.142.200',
'45.134.142.207',
'45.134.142.220',
'45.134.212.80',
'45.134.212.93',
'45.134.213.195',
'45.134.79.68',
'45.134.79.98',
'45.155.91.99',
'45.86.221.146',
'46.19.136.227',
'5.47.87.202',
'66.115.189.160',
'66.115.189.190',
'66.115.189.200',
'66.115.189.210',
'66.115.189.247',
'66.63.167.147',
'66.63.167.163',
'66.63.167.195',
'68.235.44.195',
'68.235.44.3',
'68.235.44.35',
'69.4.234.116',
'69.4.234.118',
'69.4.234.119',
'69.4.234.120',
'69.4.234.122',
'69.4.234.124',
'69.4.234.125',
'79.127.217.35',
'79.127.217.44',
'79.127.217.48',
'79.127.222.195',
'79.127.222.208',
'87.249.134.11',
'87.249.134.15',
'87.249.134.2',
'87.249.134.28',
'92.60.40.210',
'92.60.40.225',
'93.115.0.49',
'96.44.189.99',
'96.44.191.131',
'96.44.191.140',
'96.44.191.147'
)
order by event_timestamp desc
);
RETURN TABLE(res);
END
$$
```

## Monitored query history

```sql
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
$$
```

## Users with static credentials

Recommendation to remove any static credentials (passwords) stored in Snowflake
 to mitigate the risk of credential stuffing/ password spray attacks.

```sql
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
$$
```

## Most Dangerous User

```sql
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
$$
```

## Network Policy Change Management

```sql
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
$$
```

## Login failures, by User and Reason

```sql
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
$$
```

## Privileged Object Management

```sql
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
$$
```

## SCIM Token Lifecycle

```sql
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
$$
```

## Access Count By Column

```sql
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
$$
```

## Aggregate View of Access Over Time by Consumer

```sql
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
$$
```

## Shares usage statistics

```sql
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
$$
```

## Changes to listings

```sql
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
$$
```

## Reader account creation

```sql
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
$$
```

## Replication usage

```sql
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
$$
```

## Changes to shares

```sql
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
$$
```

## Table Joins By Consumer

```sql
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
$$
```

## Stale users

```sql
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
$$
```

## User to Role Ratio (larger is better)

```sql
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
$$
```

## Users by Password Age

```sql
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
$$
```

<!-- END mdsh -->
