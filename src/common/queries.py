"""Module with queries to be run in the app."""

from src.common.query_proxy import Query

NUM_FAILURES = Query("num_failures")

AUTH_BY_METHOD = Query("auth_by_method")

AUTH_BYPASSING = Query("auth_bypassing")

ACCOUNTADMIN_GRANTS = Query("accountadmin_grants")

ACCOUNTADMIN_NO_MFA = Query("accountadmin_no_mfa")

USERS_BY_OLDEST_PASSWORDS = Query("users_by_oldest_passwords")

STALE_USERS = Query("stale_users")

SCIM_TOKEN_LIFECYCLE = Query("scim_token_lifecycle")

MOST_DANGEROUS_PERSON = Query("most_dangerous_person")

MOST_BLOATED_ROLES = Query("bloated_roles")

PRIVILEGED_OBJECT_CHANGES_BY_USER = Query("privileged_object_changes_by_user")

NETWORK_POLICY_CHANGES = Query("network_policy_changes")

DEFAULT_ROLE_CHECK = Query("default_role_check")

GRANTS_TO_PUBLIC = Query("grants_to_public")

GRANTS_TO_UNMANAGED_SCHEMAS_OUTSIDE_SCHEMA_OWNER = Query(
    "grants_to_unmanaged_schemas_outside_schema_owner"
)

USER_ROLE_RATIO = Query("user_role_ratio")

AVG_NUMBER_OF_ROLE_GRANTS_PER_USER = Query("avg_number_of_role_grants_per_user")

LEAST_USED_ROLE_GRANTS = Query("least_used_role_grants")

SHARING_READER_CREATION_MONITOR = Query("sharing_reader_creation_monitor")

SHARING_SHARE_ALTER = Query("sharing_share_alter")
