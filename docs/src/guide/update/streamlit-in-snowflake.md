# Streamlit in Snowflake

Depending on the installation method, you may want to use different methods of
updating Sentry installed as Streamlit in Snowflake.

## Git integration

Application installed through the [Git
integration](../installation/streamlit-in-snowflake.md#git-integration) method
can be updated by running `ALTER GIT REPOSITORY FETCH`
([doc](https://docs.snowflake.com/en/sql-reference/sql/alter-git-repository)).

To run this command periodically, you may want to `CREATE
TASK`([doc](https://docs.snowflake.com/en/sql-reference/sql/create-task)).

## Other installation methods

Sentry is stateless, so it can be updated by re-running the [installation
instructions](../installation/streamlit-in-snowflake.md) skipping the initial
SQL code.

One difference is that when using `snow` CLI do deploy the code -- make sure to
call it with `--replace` flag: `snow streamlit deploy --replace`.

If you are using a forked repository, you can use "sync fork" functionality on
GitHub to propagate changes from main code repository to your fork.

If you have cloned the source code locally and want to retain the local
uncommitted changes, consider using `git stash` to store the local changes and
`git stash pop` to apply them.
