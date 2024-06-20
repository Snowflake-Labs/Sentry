# Streamlit in Snowflake

To update Streamlit in Snowflake application, re-run the [installation
instructions](../installation/streamlit-in-snowflake.md) skipping the initial
SQL code.

One difference is that when using `snow` CLI do deploy the code -- make sure to
call it with `--replace` flag: `snow streamlit deploy --replace`.

If you are using a forked repository, you can use "sync fork" functionality on
GitHub to propagate changes from main code repository to your fork.

If you have cloned the source code locally and want to retain the local
uncommitted changes, consider using `git stash` to store the local changes and
`git stash pop` to apply them.
