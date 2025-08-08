# Local Streamlit application

These instructions will set up a python environment to run Sentry in.

1. (if `uv` is not installed) Install uv using [steps from official
   documentation](https://docs.astral.sh/uv/getting-started/installation/).
2. Clone the [source code][src] and change current directory to its root
3. Run `uv sync --all-extras` to install all dependencies
4. Set up [Streamlit secrets][streamlit-secrets].

    If using project-specific secrets, `.streamlit` directory needs to be
    created in the root of the application.

    Ensure that `connections.default` is specified in the secrets file, for
    example:

    ```toml
    [connections.default]
    account = "<accountName>"
    user = "<userName>"
    warehouse = "<whName>"
    role = "<role>" # Any role with access to ACCOUNT_USAGE
    private_key_file = "<pathToPrivateKeyFile>"
    ```

5. Run `uv run streamlit run src/Authentication.py`
6. Open the URL provided by Streamlit in the terminal (typically
   `http://localhost:8501`)

[src]: https://github.com/Snowflake-Labs/Sentry
[streamlit-secrets]:
https://docs.streamlit.io/streamlit-community-cloud/deploy-your-app/secrets-management
