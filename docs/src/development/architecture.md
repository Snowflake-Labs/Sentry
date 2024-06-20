# Architecture

This file contains information on the project's architecture decisions and
components.

# Programming language

Main language is python, intended to be as compatible as possible with [Snowpark
python conda channel](https://repo.anaconda.com/pkgs/snowflake/).

The python code is managed through [poetry](https://python-poetry.org/). Poetry
was chosen for its support of lock files which provides some reproducibility
guarantees in the python ecosystem.

## Dependencies

The project dependencies are defined in `pyproject.toml` and locked in
`poetry.lock`. The application needs to run in all of the supported
environments:

- Native application (follows conda channel, but has additional considerations
  compared to SiS, e.g. `py38` only is supported)
- Streamlit in Snowflake (follows conda channel)
- Local streamlit (least restrictive)
- Docker container (least restrictive)

The pinned versions are an approximation of the strictest environment (Native
apps).

# CI/CD

CI/CD is implemented using [nix flake](https://nixos.org). This allows for the Github
actions to execute the exact same code as a developer would execute on their
machine providing strong repeatability and consistency guarantees.

## CI

Main CI entry point is `nix flake check`. It will perform all syntax checks and
code lints. A Github action calls `nix flake check` on commits into the main
branch.

## CD

Deployment can be triggered by manually calling corresponding Github action and
depend on Github secrets or secrets passed through environment variables.

# Project organization

Main source code resides in `./src` directory following the [src
layout](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/)
convention.

## Query files organization

The query files are located in `./src/queries` in individual directories. This
approach allows the SQL to be both imported into Python and be executed in
Snowpark session and the SQL can be run through `EXECUTE IMMEDIATE FROM`

Every query directory must have:

- the SQL code in a `.sql` file. The file contents must be executable in a
  stored procedure, a worksheet or a stored procedure[^note]
- query metadata in a `README.md` file

## Streamlit code

Main Streamlit entry point is
[Authentication.py](https://github.com/Snowflake-Labs/Sentry/blob/main/src/Authentication.py).
The
individual pages are located in `pages/` subdirectory as required by Streamlit
[multipage-apps](https://docs.streamlit.io/library/advanced-features/multipage-apps).

The pages structure was chosen to match the [original source of the application][1].

[1]:
https://quickstarts.snowflake.com/guide/security_dashboards_for_snowflake/index.html

[^note]: some queries, namely ones calling `SHOW GRANTS` require running the
    stored procedure with `CALLER` rights
    ([doc](https://community.snowflake.com/s/article/Use-of-SHOW-grants-in-stored-procedure)).
    Streamlit in Snowflake runs with owner's rights, thus such queries cannot
    currently be a part of this deployment model.
