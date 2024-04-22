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
        table_schema;
