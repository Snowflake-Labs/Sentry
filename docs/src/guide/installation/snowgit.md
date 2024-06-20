# Stored procedures

The Sentry queries can be used without the accompanying Streamlit UI. They can
be run from worksheets, notebooks, stored procedures or external systems.

The stored procedures can be deployed using [Snowflake git integration][snowgit]
using the following steps:

1. Set up API integration:

    ```sql
    CREATE OR REPLACE API INTEGRATION sentry_public_github
        API_PROVIDER=git_https_api
        API_ALLOWED_PREFIXES=('https://github.com/Snowflake-Labs/Sentry')
        enabled = true;
    ```

2. Set up git repository in currently selected database:

    ```sql
    CREATE OR REPLACE GIT REPOSITORY sentry_repo
        api_integration = sentry_public_github
        origin = "https://github.com/Snowflake-Labs/Sentry";
    ```

The individual queries can be run using `EXECUTE IMMEDIATE FROM`, e.g.:

```sql
EXECUTE IMMEDIATE FROM @sentry_repo/branches/main/src/queries/auth_by_method/auth_by_method.sql;
```

Alternatively, the stored procedures can be created from a single file:

```sql
EXECUTE IMMEDIATE FROM @sentry_repo/branches/main/deployment_models/git-repository/create_all.sql;
```

[snowgit]: https://docs.snowflake.com/en/developer-guide/git/git-overview
