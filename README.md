This is a repository containing the Streamlit version of the [Snowflake
security dashboards][1].

# About

This project is first and foremost a set of tools aimed to help with step #2 of
CIRP incident response, **identification**. It is not meant to be a complete
end-to-end solution, but rather a reference implementation that needs to be
adapted to the company's needs.

This project contains a set of queries with reference information that explains
what kind of information those queries provide.

The provided tools can be used individually through stored procedures.
Alternatively, the project contains a Streamlit in Snowflake UI that can be
deployed as:

- a Streamlit application
- Snowflake native application
- docker image
- stored procedures

Alternatively the queries are kept as `.sql` files in a [dedicated directory][4]
with accompanying README files.

Information regarding the project architecture and development environment is
kept in [DEVELOPMENT.md](./DEVELOPMENT.md).

# Deployment

## Streamlit in Snowflake

The repository includes an [action][2] that deploys the application in an account
configured through Github action secrets.

To use this:

1. Fork/clone this repository
2. Run the [SQL setup](./deployment_models/Streamlit-in-Snowflake.sql)
3. Fill in the action secrets:

    - `SIS_GRANT_TO_ROLE` – which role should have access to the Streamlit\
(e.g. `ACCOUNTADMIN`)
    - `SIS_QUERY_WAREHOUSE` – warehouse for running Streamlit
    - `SNOWFLAKE_ACCOUNT` – which Snowflake account to deploy Streamlit in
    - `SNOWFLAKE_DATABASE` – which Snowflake database to deploy Streamlit in
    - `SNOWFLAKE_SCHEMA` – which Snowflake schema to deploy Streamlit in
    - `SNOWFLAKE_USER` – user to authenticate
    - `SNOWFLAKE_PASSWORD` – password to authenticate
    - `SNOWFLAKE_ROLE` – authentication role
    - `SNOWFLAKE_WAREHOUSE` – warehouse to execute deployment queries

4. Run the "Deploy Streamlit in Snowflake" action

## Streamlit in local docker container

1. Clone this repository and change current directory to its root
2. Create a directory `.streamlit` in the root of the cloned repository
3. Create a file `secrets.toml` inside `.streamlit` directory with contents
   like:

   ```toml
   [connections.default]
   account = "<accountName>"
   user = "<userName>"
   password = "<superSecretPassword>"
   warehouse = "<whName>"
   role = "<role>" # Any role with access to ACCOUNT_USAGE
   ```

    See more information on the Stremalit secrets [here][3].

4. Build and run the docker image:

    ```shell
    $ docker build . -t sentry:latest -f deployment_models/local-docker/Dockerfile
    ...
    naming to docker.io/library/sentry:latest
    $ docker run --rm --mount type=bind,source=$(pwd)/.streamlit,target=/app/.streamlit,readonly --publish-all sentry:latest
    ...
      You can now view your Streamlit app in your browser.
    ...
    ```

    Replace `$(pwd)/.streamlit` with a path to the directory containing
    [Streamlit secrets toml file][3] if using a different secrets location.

    `--publish-all` will assign a random port to the container; you can use
    `docker ps` to determine which port is forwarded to `8501` inside the
    container.

5. (if needed) find out the port that Docker assigned to the container using
   `docker ps`:

   ```shell
   $ docker ps --format "{{.Image}}\t{{.Ports}}"
     sentry:latest	0.0.0.0:55000->8501/tcp
   ```

6. Open `http://localhost:55000`

## Stored procedure deployment

[*Separate doc file*](./deployment_models/git-repository/README.md).

[1]:
https://quickstarts.snowflake.com/guide/security_dashboards_for_snowflake/index.html

[2]:
./.github/workflows/deploy-streamlit-in-snowflake.yml

[3]:
https://docs.streamlit.io/streamlit-community-cloud/deploy-your-app/secrets-management

[4]: ./src/queries

## Contributing

Please refer to [CONTRIBUTING.md](CONTRIBUTING.md).
