# Installation

This section contains instructions on installing Sentry in individual Snowflake
accounts.

## Using nix

Nix applications automate most of the actions to set up and maintain this
project. `direnv` and the development shell provide help on various commands.

For example, to deploy Streamlit in Snowflake:

```bash
sis-setUp
# <set up deployment user's authentication>
sis-deploy
sis-open
sis-tearDown
```

Upon activating the nix development shell, run `menu` for all commands.
