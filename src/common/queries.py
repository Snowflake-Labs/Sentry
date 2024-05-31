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

SHARING_LISTING_ALTER = Query("sharing_listings_alter")

SHARING_LISTING_USAGE = Query("sharing_listing_usage")

SHARING_REPLICATION_HISTORY = Query("sharing_replication_history")

SHARING_AGGREGATE_ACCESS_OVER_TIME_BY_CONSUMER = Query(
    "sharing_access_over_time_by_consumer"
)

SHARING_ACCESS_COUNT_BY_COLUMN = Query("sharing_access_count_by_column")

SHARING_TABLE_JOINS_BY_CONSUMER = Query("sharing_table_joins_by_consumer")

# May 30 ttps guidance

IP_LOGINS = Query("may30_ttps_guidance_ip_logins")

FACTOR_BREAKDOWN = Query("may30_ttps_guidance_factor_breakdown")

IPS_WITH_FACTOR = Query("may30_ttps_guidance_ips_with_factor")

STATIC_CREDS = Query("may30_ttps_guidance_static_creds")

QUERY_HISTORY = Query("may30_ttps_guidance_query_history")

ANOMALOUS_APPLICATION_ACCESS = Query("may30_ttps_guidance_anomalous_application_access")
