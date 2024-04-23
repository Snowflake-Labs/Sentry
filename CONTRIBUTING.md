# Contributing to Sentry

Upstreaming a code contribution should be done by forking this repository,
creating a feature branch and opening a pull request.

When adding a new query or changing an existing one, the [documentation needs to
be re-generated](#generating-documentation).

Make sure to check [DEVELOPMENT.md](./DEVELOPMENT.md) for an overview of the
architectural decisions of the project.

# Setting up development environment

## Python

`poetry` is used to manage the Python environment. Most IDEs can create a
virtual environment from the `pyproject.toml`. Alternatively, use `poetry
install --with=dev` in the project root to create it.

## Pre-commit

The project uses pre-commit configuration embedded into `flake.nix` as a
separate file [`linters.nix`](./linters.nix).

To install it using `nix`:

```bash
nix develop .#pre-commit --command bash -c "exit"
```

Alternatively, have the pre-commit run `ruff` and `isort`. For more up to date
list of checkers, see the `linters.nix` file. Since the `pre-commit` is
only a part of the centrally-managed CI, `pre-commit-config.yml` is ignored by
git.

## All checks

The main entry point to all linters is `nix flake check`. The repository's CI is
configured to run it on commits to the branch

# Deploying into a controlled Snowflake account

Repository comes with GitHub actions that manage the deployment. Under the hood
the actions are implemented by `nix` applications, so can be triggered locally
to the same effect.

# Generating documentation

## Git-repository documentation

1. Use [`mdsh`][1] to update `README.md` in `git-repository` directory:

    ```bash
    cd $PRJ_ROOT
    mdsh --inputs ./deployment_models/git-repository/README.md
    ```

    It will invoke nix-based application that generates documentation in the
    defined block.

2. Use `nix` to generate the single file with all stored procedures:

    ```bash
    nix run .#mkSingleCreateSprocFile > ./deployment_models/git-repository/create_all.sql
    ```

[1]: https://github.com/zimbatm/mdsh
