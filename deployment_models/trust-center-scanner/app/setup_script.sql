CREATE APPLICATION ROLE IF NOT EXISTS trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA stale_users;

CREATE OR REPLACE PROCEDURE stale_users.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns users that have not logged in for a while.

Notes:
    - Query taken as is
TODO:
    - Make the threshold customizable
    - Increase severity if the proportion of the users is high?
"""

import re

from helpers import build_entity, limit_entities, scanner

CUTOFF_DAYS = 30

# Ideally should not change to keep reusing SQL as much as possible
# This has a downside – the logic here has to re-parse the output...
QUERY = """
SELECT
    name,
    datediff("day", nvl(last_success_login, created_on), current_timestamp()) || ' days ago' Last_Login
FROM snowflake.account_usage.users
WHERE deleted_on is null
ORDER BY datediff("day", nvl(last_success_login, created_on), current_timestamp()) desc;"""


@scanner(
    risk_id="SECRETS-13",
    risk_name="Stale users",
    risk_description="User accounts that have not logged in for an extended period may be abandoned or unnecessary.",
    suggested_action="Disable or delete inactive accounts after verifying they are no longer needed",
    impact="Inactive accounts are prime targets for attackers as unauthorized access may go unnoticed for extended periods",
    severity="LOW",
)
@limit_entities(1000)
def main(session, run_id):
    """Retrieve users who have not logged in for a while."""
    data = session.sql(QUERY).collect()

    entities = []

    for user in data:
        match = re.match(r"^(\d+)", user["LAST_LOGIN"])

        if match:
            days_ago = int(match.group(1))
            if days_ago > CUTOFF_DAYS:
                entities.append(
                    build_entity(
                        name=user["NAME"],
                        object_type="USER",
                        detail={"last_login": user["LAST_LOGIN"]},
                    )
                )
        else:
            # Could not parse last_login - report for manual review
            entities.append(
                build_entity(
                    name=user["NAME"],
                    object_type="USER",
                    detail={
                        "last_login": user["LAST_LOGIN"],
                        "parse_error": "Could not extract days from last_login field",
                    },
                )
            )

    return entities

  $$;

GRANT USAGE ON SCHEMA stale_users
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE stale_users.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA grants_to_public;

CREATE OR REPLACE PROCEDURE grants_to_public.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns recent grants to PUBLIC role as low priority signals.

Notes:
    - QUERY_HISTORY lookups often require a bigger warehouse to complete faster
    - Added `query_id` to the output

TODO:
    - Make the severity customizable
    - Make the lookback period customizable
"""

from helpers import build_entity, limit_entities, scanner

CUTOFF_DAYS = 30

QUERY = f"""
select user_name, role_name, query_text, end_time, query_id
    from SNOWFLAKE.ACCOUNT_USAGE.query_history where execution_status = 'SUCCESS'
    and query_type = 'GRANT'
    and query_text ilike '%to%public%'
    and DATEDIFF(day, END_TIME, CURRENT_DATE()) < {CUTOFF_DAYS};
"""


@scanner(
    risk_id="SECRETS-8",
    risk_name="Grants to PUBLIC role",
    risk_description="Recent GRANT statements assigned privileges to the PUBLIC role, which is automatically assigned to all users.",
    suggested_action="Review these grants and revoke any that expose sensitive resources unnecessarily",
    impact="Grants to PUBLIC expose resources to all users in the account, potentially leaking sensitive data or enabling unauthorized access",
    severity="LOW",
    scanner_type="DETECTION",
)
@limit_entities(1000)
def main(session, run_id):
    """Retrieve the grants to PUBLIC role in Trust Center-compat format."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["QUERY_ID"],
            object_type="QUERY",
            detail={
                "query_text": row["QUERY_TEXT"],
                "granting_user": row["USER_NAME"],
                "granting_role": row["ROLE_NAME"],
                "end_time": row["END_TIME"],
            },
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA grants_to_public
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE grants_to_public.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA privileged_object_changes;

CREATE OR REPLACE PROCEDURE privileged_object_changes.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns privileged object changes done by users.

Notes:
    - Added CUTOFF_DAYS to the query

TODO:
    - Maybe add ability to configure the object types that are managed
"""

from helpers import build_entity, limit_entities, scanner

CUTOFF_DAYS = 30

QUERY = f"""
SELECT
    query_id,
    query_text,
    user_name,
    role_name,
    end_time
FROM
    snowflake.account_usage.query_history
WHERE
    execution_status = 'SUCCESS'
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
    AND DATEDIFF(day, END_TIME, CURRENT_DATE()) < {CUTOFF_DAYS}
ORDER BY
    end_time DESC
"""


@scanner(
    risk_id="SECRETS-3",
    risk_name="Privileged Object Management",
    risk_description="Changes to sensitive objects including roles, integrations, shares, stages, and ownership transfers were detected.",
    suggested_action="Review each change to ensure it was authorized and follows change management procedures",
    impact="Unmonitored privileged object changes could introduce security holes, data loss, or unauthorized integrations",
    severity="LOW",
    scanner_type="DETECTION",
)
@limit_entities(1000)
def main(session, run_id):
    """Return privileged object changes done by users."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["QUERY_ID"],
            object_type="QUERY",
            detail={
                "query_text": row["QUERY_TEXT"],
                "changing_user": row["USER_NAME"],
                "end_time": row["END_TIME"],
            },
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA privileged_object_changes
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE privileged_object_changes.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA scim_token_lifecycle;

CREATE OR REPLACE PROCEDURE scim_token_lifecycle.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Raises an alert if the token will expire soon.

Notes:
    - Added a tiny regex to extract the name of the token
    - Assuming calls to GENERATE_SCIM_ACCESS_TOKEN -- determine maximum expiration date based on the latest call
    - Added a filter at the end of the query to only print names and expires_in_days fields

TODO:
    - Configurable thresholds (LOW -> MEDIUM -> ...)
"""

from helpers import build_entity, limit_entities, scanner

ALERT_THRESHOLD = 30
QUERY = """
select
    user_name as by_whom,
    datediff('day', start_time, current_timestamp()) || ' days ago' as created_on,
    ADD_MONTHS(start_time, 6) as expires_on,
    datediff(
        'day',
        current_timestamp(),
        ADD_MONTHS(end_time, 6)
    ) as expires_in_days,
    query_text,
    REGEXP_SUBSTR(query_text, 'generate_scim_access_token\\\\(''(\\\\w+)', 1, 1, 'ei', 1) as SECURITY_INTEGRATION,
    MAX(expires_in_days) OVER (PARTITION BY SECURITY_INTEGRATION) AS MAX_EXP

from
    SNOWFLAKE.ACCOUNT_USAGE.query_history
where
    execution_status = 'SUCCESS'
    and query_text ilike 'select%SYSTEM$GENERATE_SCIM_ACCESS_TOKEN%'
    and query_text not ilike 'select%where%SYSTEM$GENERATE_SCIM_ACCESS_TOKEN%'
order by
    expires_in_days
->> SELECT SECURITY_INTEGRATION, MAX_EXP
    FROM $1
    WHERE
        SECURITY_INTEGRATION IS NOT NULL -- exclude cases where regex did not match
        AND MAX_EXP <= """ + str(ALERT_THRESHOLD) + """
    GROUP BY ALL
"""


@scanner(
    risk_id="SECRETS-5",
    risk_name="SCIM Token Lifecycle",
    risk_description="SCIM access tokens are approaching expiration and may disrupt identity provisioning.",
    suggested_action="Regenerate expiring SCIM tokens before they expire to maintain uninterrupted identity provisioning",
    impact="Expired SCIM tokens will break identity provisioning, causing authentication failures and user access disruptions",
    severity="MEDIUM",
)
@limit_entities(1000)
def main(session, run_id):
    """Return SCIM tokens that may be expiring soon."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["SECURITY_INTEGRATION"],
            object_type="SECURITY INTEGRATION",
            detail={"expires_in_days": row["MAX_EXP"]},
        )
        for row in data
    ]


  $$;

GRANT USAGE ON SCHEMA scim_token_lifecycle
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE scim_token_lifecycle.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA grants_to_unmanaged_sch;

CREATE OR REPLACE PROCEDURE grants_to_unmanaged_sch.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns grants to unmanaged schemas outside schema owner."""

from helpers import build_entity, limit_entities, scanner

QUERY = """
select table_catalog,
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
"""


@scanner(
    risk_id="SECRETS-10",
    risk_name="Grants to unmanaged schemas outside schema owner",
    risk_description="Grants on objects in unmanaged schemas were made by users other than the schema owner.",
    suggested_action="Review these grants and consider converting schemas to managed access or consolidating grant authority",
    impact="Uncontrolled grants bypass schema ownership controls, creating shadow access paths and complicating access audits",
    severity="LOW",
)
@limit_entities(1000)
def main(session, run_id):
    """Return grants to unmanaged schemas outside schema owner."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["TABLE_SCHEMA"],
            object_type="SCHEMA",
            detail={
                "table_catalog": row["TABLE_CATALOG"],
                "table_schema": row["TABLE_SCHEMA"],
                "schema_owner": row["SCHEMA_OWNER"],
                "privilege": row["PRIVILEGE"],
                "granted_by": row["GRANTED_BY"],
                "granted_on": row["GRANTED_ON"],
                "name": row["NAME"],
                "granted_to": row["GRANTED_TO"],
                "grantee_name": row["GRANTEE_NAME"],
                "grant_option": row["GRANT_OPTION"],
            },
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA grants_to_unmanaged_sch
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE grants_to_unmanaged_sch.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA default_role_check;

CREATE OR REPLACE PROCEDURE default_role_check.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns users with default role set to ACCOUNTADMIN.

Notes:
    - Reformatted query
    - Filtered query to only return users whose default role is ACCOUNTADMIN
"""

from helpers import build_entity, limit_entities, scanner

QUERY = """
SELECT
    role,
    grantee_name,
    default_role
FROM
    SNOWFLAKE.ACCOUNT_USAGE."GRANTS_TO_USERS"
    JOIN "SNOWFLAKE"."ACCOUNT_USAGE"."USERS"
        ON users.name = grants_to_users.grantee_name
WHERE
    role = 'ACCOUNTADMIN'
    AND grants_to_users.deleted_on IS NULL
    AND users.deleted_on IS NULL
ORDER BY grantee_name
->> SELECT grantee_name FROM $1 WHERE DEFAULT_ROLE = 'ACCOUNTADMIN'
"""


@scanner(
    risk_id="SECRETS-9",
    risk_name="Default Role is ACCOUNTADMIN",
    risk_description="Users have their default role set to ACCOUNTADMIN, operating with full administrative privileges by default.",
    suggested_action="Change default role to a less privileged role; users can still switch to ACCOUNTADMIN when needed",
    impact="Users defaulting to ACCOUNTADMIN may inadvertently execute privileged operations, increasing risk of accidental or malicious damage",
    severity="LOW",
)
@limit_entities(1000)
def main(session, run_id):
    """Return users whose default role is ACCOUNTADMIN."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["GRANTEE_NAME"],
            object_type="USER",
            detail={},
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA default_role_check
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE default_role_check.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA roles_scanner;

CREATE OR REPLACE PROCEDURE roles_scanner.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns Low-priority findings for GRANTS of the role ACCOUNTADMIN to users.

Notes:
    - QUERY_HISTORY lookups often require a bigger warehouse to complete faster
    - Query was slightly changed from original. It now retrieves structured
      columns rather than creating a user-facing message. It also parses the
      grantee of the role as a separate column

TODO:
    - Make the severity customizable
    - Make the lookback period customizable
"""

import re

from helpers import build_entity, limit_entities, scanner

CUTOFF_DAYS = 30

QUERY = f"""
SELECT
    query_id,
    query_text,
    user_name,
    end_time,
FROM SNOWFLAKE.ACCOUNT_USAGE.query_history
WHERE
    execution_status = 'SUCCESS'
    and query_type = 'GRANT'
    and query_text ilike '%grant%accountadmin%to%'
    and DATEDIFF(day, END_TIME, CURRENT_DATE()) < {CUTOFF_DAYS};
"""


@scanner(
    risk_id="ROLES-7",
    risk_name="Grants of ACCOUNTADMIN role",
    risk_description="Detects recent grants of the ACCOUNTADMIN role to users, which provides full administrative access to the Snowflake account.",
    suggested_action="Verify each grant was authorized and follows your organization's privileged access management policy",
    impact="Unauthorized ACCOUNTADMIN access could lead to full account compromise, data exfiltration, or malicious configuration changes",
    severity="LOW",
    scanner_type="DETECTION",
)
@limit_entities(1000)
def main(session, run_id):
    """Retrieve the ACCOUNTADMIN grants in Trust Center-compat format."""
    data = session.sql(QUERY).collect()
    entities = []

    for grant in data:
        query_text = grant["QUERY_TEXT"]
        match = re.search(r"TO\s+USER\s+(?:IDENTIFIER\(['\"\s]*)?(\w+)", query_text, re.IGNORECASE)

        if match:
            entities.append(
                build_entity(
                    name=match.group(1),
                    object_type="USER",
                    detail={
                        "query_text": query_text,
                        "granted_by": grant["USER_NAME"],
                        "granted_on": grant["END_TIME"],
                    },
                )
            )
        else:
            # Could not parse user - report the query itself for manual review
            entities.append(
                build_entity(
                    name=grant["QUERY_ID"],
                    object_type="QUERY",
                    detail={
                        "query_text": query_text,
                        "executed_by": grant["USER_NAME"],
                        "executed_on": grant["END_TIME"],
                        "parse_error": "Could not extract target user from query text",
                    },
                )
            )

    return entities

  $$;

GRANT USAGE ON SCHEMA roles_scanner
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE roles_scanner.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA bloated_roles;

CREATE OR REPLACE PROCEDURE bloated_roles.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns roles with the largest amount of effective privileges.

Notes:
    - Query taken as is

TODO:
    - configurable threshold
"""

from helpers import build_entity, limit_entities, scanner

THRESHOLD = 100

QUERY = """
--Role Hierarchy
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
"""


@scanner(
    risk_id="ROLES-5",
    risk_name="Bloated roles",
    risk_description="Roles have an unusually large number of effective privileges, potentially violating least-privilege principles.",
    suggested_action="Review these roles and consider splitting them into more granular, purpose-specific roles",
    impact="Overly permissive roles increase blast radius if compromised and violate least-privilege principles",
    severity="LOW",
)
@limit_entities(1000)
def main(session, run_id):
    """Return roles with the largest amount of effective privileges."""
    data = session.sql(QUERY).filter(f"num_of_privs > {THRESHOLD}").collect()

    return [
        build_entity(
            name=row["ROLE"],
            object_type="ROLE",
            detail={"privileges_count": row["NUM_OF_PRIVS"]},
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA bloated_roles
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE bloated_roles.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA least_used_role_grants;

CREATE OR REPLACE PROCEDURE least_used_role_grants.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns Least Used Role Grants.

Notes:
    - Query formatted
    - Removed 'days ago' from query

TODO:
    - configurable thresholds
    - Maybe separate this into "completely unused roles" and "roles used too long ago"
"""

from helpers import build_entity, limit_entities, scanner

QUERY = """
WITH
    least_used_roles (user_name, role_name, last_used, times_used)
    AS
    (SELECT
         user_name,
         role_name,
         max(end_time),
         count(*)
     FROM
         SNOWFLAKE.ACCOUNT_USAGE.query_history
     GROUP BY
         user_name,
         role_name
     ORDER BY
     user_name, role_name)
SELECT
    grantee_name,
    role,
    nvl(last_used, (select min(start_time) from SNOWFLAKE.ACCOUNT_USAGE.query_history)) last_used,
    nvl(times_used, 0) times_used, datediff(day, created_on, current_timestamp()) used_days_ago
FROM
    SNOWFLAKE.ACCOUNT_USAGE.grants_to_users
LEFT JOIN
    least_used_roles ON
        user_name = grantee_name
        AND role = role_name
WHERE
    deleted_on IS NULL
ORDER BY
    last_used,
    times_used,
    used_days_ago desc
"""


@scanner(
    risk_id="ROLES-3",
    risk_name="Least Used Role Grants",
    risk_description="Role grants to users have rarely or never been used, indicating over-provisioning of access.",
    suggested_action="Review these role grants and revoke any that are no longer needed",
    impact="Unused role grants represent dormant access that could be exploited if credentials are compromised",
    severity="LOW",
)
@limit_entities(1000)
def main(session, run_id):
    """Return least used role grants."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["ROLE"],
            object_type="ROLE",
            detail={
                "grantee_name": row["GRANTEE_NAME"],
                "last_used": row["LAST_USED"],
                "times_used": row["TIMES_USED"],
                "used_days_ago": row["USED_DAYS_AGO"],
            },
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA least_used_role_grants
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE least_used_role_grants.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA most_dangerous_user;

CREATE OR REPLACE PROCEDURE most_dangerous_user.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns users with largest amount of roles.

Notes:
    - Query taken as is

TODO:
    - configurable threshold
"""

from helpers import build_entity, limit_entities, scanner

THRESHOLD = 4

QUERY = """
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
) --Most Dangerous Man - final query
SELECT
    grantee_name as user,
    count(a.role) num_of_roles,
    sum(num_of_privs) num_of_privs
FROM
    SNOWFLAKE.ACCOUNT_USAGE.grants_to_users u
    join role_path_privs_agg a ON a.role = u.role
WHERE
    u.deleted_on IS NULL
GROUP BY
    user
ORDER BY
    num_of_privs DESC
"""


@scanner(
    risk_id="USER-1",
    risk_name="Users with large amount of roles",
    risk_description="Users have been granted an unusually high number of roles, concentrating broad access in single accounts.",
    suggested_action="Review role assignments and remove any that are not required for the user's current responsibilities",
    impact="Users with excessive roles have broad access that increases risk of privilege abuse or lateral movement if compromised",
    severity="LOW",
)
@limit_entities(1000)
def main(session, run_id):
    """Retrieve the users x roles count; get users having more roles than a specified threshold."""
    data = session.sql(QUERY).filter(f"num_of_roles > {THRESHOLD}").collect()

    return [
        build_entity(
            name=row["USER"],
            object_type="USER",
            detail={
                "roles_count": row["NUM_OF_ROLES"],
                "privileges_count": row["NUM_OF_PRIVS"],
            },
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA most_dangerous_user
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE most_dangerous_user.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA users_by_oldest_passwords;

CREATE OR REPLACE PROCEDURE users_by_oldest_passwords.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns users with password older than a threshold.

Notes:
    - Removed the flavor 'days ago' text from the query
    - Added cutoff to password expiration

TODO:
    - Make the threshold customizable
"""

from helpers import build_entity, limit_entities, scanner

CUTOFF_DAYS = 365

QUERY = f"""
SELECT
    name,
    datediff('day', password_last_set_time, current_timestamp()) as password_last_changed
FROM
    snowflake.account_usage.users
WHERE
    deleted_on is null
    AND password_last_set_time IS NOT NULL
    AND password_last_changed >= {CUTOFF_DAYS}
ORDER BY
    password_last_set_time;
"""


@scanner(
    risk_id="USER-3",
    risk_name="Users by Password Age",
    risk_description="User passwords have not been changed in over a year, exceeding typical password rotation policies.",
    suggested_action="Enforce password rotation or migrate these users to SSO/MFA authentication methods",
    impact="Stale passwords are more likely to be compromised through credential stuffing or brute force attacks",
    severity="LOW",
)
@limit_entities(1000)
def main(session, run_id):
    """Return users with password older than a threshold."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["NAME"],
            object_type="USER",
            detail={"password_last_changed": row["PASSWORD_LAST_CHANGED"]},
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA users_by_oldest_passwords
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE users_by_oldest_passwords.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA network_policy_changes;

CREATE OR REPLACE PROCEDURE network_policy_changes.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns queries that changes network policies.

Notes:
    - Query changed to structured output
    - Added cutoff days
"""

from helpers import build_entity, limit_entities, scanner

CUTOFF_DAYS = 30

QUERY = f"""
SELECT
    query_id,
    query_text,
    user_name,
    end_time
FROM SNOWFLAKE.ACCOUNT_USAGE.query_history
WHERE execution_status = 'SUCCESS'
AND DATEDIFF(day, END_TIME, CURRENT_DATE()) < {CUTOFF_DAYS}
AND (
    query_type IN ('CREATE_NETWORK_POLICY', 'ALTER_NETWORK_POLICY', 'DROP_NETWORK_POLICY')
    OR (
        (query_text ILIKE '% set network_policy%' OR query_text ILIKE '% unset network_policy%')
        AND query_type NOT IN ('SELECT', 'UNKNOWN')
    )
)
ORDER BY end_time DESC;
"""


@scanner(
    risk_id="NETWORK_POLICY_CHANGES",
    risk_name="Network Policy Change Management",
    risk_description="Changes to network policies were detected, including creation, modification, deletion, or assignment.",
    suggested_action="Review each network policy change to ensure it maintains appropriate network access restrictions",
    impact="Unauthorized network policy changes could expose the account to untrusted networks or block legitimate access",
    severity="LOW",
    scanner_type="DETECTION",
)
@limit_entities(1000)
def main(session, run_id):
    """Retrieve the changes to network policies."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["QUERY_ID"],
            object_type="QUERY",
            detail={
                "query_text": row["QUERY_TEXT"],
                "changing_user": row["USER_NAME"],
                "end_time": row["END_TIME"],
            },
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA network_policy_changes
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE network_policy_changes.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA num_failures;

CREATE OR REPLACE PROCEDURE num_failures.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns users with recent login failures exceeding a threshold.

Notes:
    - Added CUTOFF_DAYS to the query

TODO:
    - Allow configuring the login failures threshold
"""

from helpers import build_entity, limit_entities, scanner

CUTOFF_DAYS = 30

QUERY = f"""
SELECT
    user_name,
    error_message,
    count(*) num_of_failures
FROM
    snowflake.account_usage.login_history
WHERE
    IS_SUCCESS = 'NO'
    AND DATEDIFF(day, EVENT_TIMESTAMP, CURRENT_DATE()) < {CUTOFF_DAYS}
GROUP BY
    user_name,
    error_message
ORDER BY
    num_of_failures DESC
"""


@scanner(
    risk_id="AUTH-1",
    risk_name="Login failures",
    risk_description="Users experienced recent failed login attempts, which may indicate credential attacks or misconfiguration.",
    suggested_action="Investigate repeated failures for signs of attack; verify legitimate users have correct credentials",
    impact="Repeated login failures may indicate brute force attacks or credential stuffing attempts against user accounts",
    severity="MEDIUM",
    scanner_type="DETECTION",
)
@limit_entities(1000)
def main(session, run_id):
    """Return users with recent login failures exceeding a threshold."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["USER_NAME"],
            object_type="USER",
            detail={
                "error_message": row["ERROR_MESSAGE"],
                "num_of_failures": row["NUM_OF_FAILURES"],
            },
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA num_failures
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE num_failures.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA reader_creation_monitor;

CREATE OR REPLACE PROCEDURE reader_creation_monitor.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns queries that created a managed account.

Notes:
    - Added CUTOFF_DAYS to the query
    - Extracted specific columns from the query

TODO:
    - Maybe allow configuring whether to report on only successful queries
"""

from helpers import build_entity, limit_entities, scanner

CUTOFF_DAYS = 30

QUERY = f"""
select
    user_name,
    end_time,
    execution_status,
    query_text,
    query_id
from
    SNOWFLAKE.ACCOUNT_USAGE.query_history
WHERE
    query_type = 'CREATE'
    AND query_text ilike '%managed%account%'
    AND DATEDIFF(day, END_TIME, CURRENT_DATE()) < {CUTOFF_DAYS}
ORDER BY
    end_time desc;
"""


@scanner(
    risk_id="SHARING-1",
    risk_name="Reader account creation",
    risk_description="Attempts to create managed (reader) accounts were detected, which allow sharing data with external consumers.",
    suggested_action="Verify each reader account creation was authorized and follows your data sharing governance policy",
    impact="Unauthorized reader accounts could provide persistent external access to shared data outside normal governance controls",
    severity="LOW",
    scanner_type="DETECTION",
)
@limit_entities(1000)
def main(session, run_id):
    """Return attempts to create a managed account."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["QUERY_ID"],
            object_type="QUERY",
            detail={
                "query_text": row["QUERY_TEXT"],
                "user": row["USER_NAME"],
                "execution_status": row["EXECUTION_STATUS"],
                "end_time": row["END_TIME"],
            },
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA reader_creation_monitor
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE reader_creation_monitor.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA listing_changes;

CREATE OR REPLACE PROCEDURE listing_changes.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns queries that changed listings.

Notes:
    - Added CUTOFF_DAYS to the query
    - Query changed to structured output
"""

from helpers import build_entity, limit_entities, scanner

CUTOFF_DAYS = 30

QUERY = f"""
SELECT
    query_id,
    user_name,
    end_time,
    execution_status,
    query_text
FROM
    SNOWFLAKE.ACCOUNT_USAGE.query_history
WHERE
    query_type = 'ALTER'
    AND query_text ILIKE '%alter%listing%'
    AND DATEDIFF(day, END_TIME, CURRENT_DATE()) < {CUTOFF_DAYS}
ORDER BY
    end_time DESC;
"""


@scanner(
    risk_id="SHARING-3",
    risk_name="Changes to listings",
    risk_description="Recent ALTER LISTING operations modified Snowflake Marketplace or private listing configurations.",
    suggested_action="Verify each listing modification was authorized and maintains appropriate data access controls",
    impact="Unreviewed listing changes could expose sensitive data to unintended consumers or disrupt existing data sharing agreements",
    severity="LOW",
    scanner_type="DETECTION",
)
@limit_entities(1000)
def main(session, run_id):
    """Retrieve the changes to listings."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["QUERY_ID"],
            object_type="QUERY",
            detail={
                "query_text": row["QUERY_TEXT"],
                "changing_user": row["USER_NAME"],
                "end_time": row["END_TIME"],
            },
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA listing_changes
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE listing_changes.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;

CREATE OR ALTER VERSIONED SCHEMA share_alter;

CREATE OR REPLACE PROCEDURE share_alter.scan(
    run_id VARCHAR)
  RETURNS TABLE(
    risk_id VARCHAR,
    risk_name VARCHAR,
    total_at_risk_count NUMBER,
    scanner_type VARCHAR,
    risk_description VARCHAR,
    suggested_action VARCHAR,
    impact VARCHAR,
    severity VARCHAR,
    at_risk_entities ARRAY
  )
  LANGUAGE PYTHON
  IMPORTS = ('/common_code/helpers.py')
  HANDLER='main'
RUNTIME_VERSION=3.12
PACKAGES = ('snowflake-snowpark-python')

  AS
  $$
"""Returns queries that changed shares.

Notes:
    - Added CUTOFF_DAYS to the query
    - Query changed to structured output
"""

from helpers import build_entity, limit_entities, scanner

CUTOFF_DAYS = 30

QUERY = f"""
SELECT
    query_id,
    user_name,
    end_time,
    execution_status,
    query_text
FROM
    SNOWFLAKE.ACCOUNT_USAGE.query_history
WHERE
    query_type = 'ALTER'
    AND query_text ILIKE '%alter%share%'
    AND DATEDIFF(day, END_TIME, CURRENT_DATE()) < {CUTOFF_DAYS}
ORDER BY
    end_time DESC
"""


@scanner(
    risk_id="SHARING-2",
    risk_name="Changes to shares",
    risk_description="Recent ALTER SHARE operations modified data sharing configurations with external accounts.",
    suggested_action="Verify each share modification was authorized and aligns with data governance policies",
    impact="Unauthorized share modifications could leak data to external parties or revoke access from legitimate consumers",
    severity="LOW",
    scanner_type="DETECTION",
)
@limit_entities(1000)
def main(session, run_id):
    """Retrieve the changes to shares."""
    data = session.sql(QUERY).collect()

    return [
        build_entity(
            name=row["QUERY_ID"],
            object_type="QUERY",
            detail={
                "query_text": row["QUERY_TEXT"],
                "changing_user": row["USER_NAME"],
                "end_time": row["END_TIME"],
            },
        )
        for row in data
    ]

  $$;

GRANT USAGE ON SCHEMA share_alter
  TO APPLICATION ROLE trust_center_integration_role;

GRANT USAGE ON PROCEDURE share_alter.scan(VARCHAR)
  TO APPLICATION ROLE trust_center_integration_role;
