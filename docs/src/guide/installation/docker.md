# Docker container

These instructions will set up a Docker container with the application.

1. Clone the [source code][src] and change current directory to its root
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

    See more information on the Streamlit secrets [here][streamlit-secrets].

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
    [Streamlit secrets toml file][streamlit-secrets] if using a different
    secrets location.

    `--publish-all` will assign a random port to the container; you can use
    `docker ps` to determine which port is forwarded to `8501` inside the
    container.

5. (if needed) find out the port that Docker assigned to the container using
   `docker ps`:

   ```shell
   $ docker ps --format "{{.Image}}\t{{.Ports}}"
     sentry:latest	0.0.0.0:55000->8501/tcp
   ```

6. Open `http://localhost:55000` in your browser

[src]: https://github.com/Snowflake-Labs/Sentry
[streamlit-secrets]:
https://docs.streamlit.io/streamlit-community-cloud/deploy-your-app/secrets-management
