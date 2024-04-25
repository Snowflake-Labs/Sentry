/**
  Contains Nix flake application to generate the documentation components.

  Since the script relies on python classes to handle Queries, it uses poetry.
*/
{ writeShellApplication }:
let
  /** Produces program for an app that is a wrapper around a small script in python. */
  wrapPythonScript = { name, pythonScript }:
    {
      type = "app";
      program = writeShellApplication {
        inherit name;
        runtimeInputs = [ ]; # NOTE: if intended to run in CI environment -- this would need poetry
        text = ''
          # halt and catch fire if docker is not available
          command -v poetry >/dev/null 2>&1 || { echo >&2 "poetry binary not available in PATH; exiting"; exit 1; }

          # silence pushd and popd
          pushd () {
            command pushd "$@" > /dev/null
          }

          popd () {
            # Note that this wrapper removes "$@" as it's not used in the script
            command popd > /dev/null
          }

          function exit_trap(){
            popd
            popd
          }
          trap exit_trap EXIT # go back to original dir regardless of the exit codes

          pushd "''${PRJ_ROOT:-$(git rev-parse --show-toplevel)}"

          POETRY_ENV_PATH=$(poetry env info --path)

          if [ -z "$POETRY_ENV_PATH" ]; then
            echo "Poetry environment path is not set, check the interpreter"
            exit
          fi

          # shellcheck disable=SC1091
          source "$POETRY_ENV_PATH/bin/activate"

          pushd "src"

          python -c "${pythonScript}"
        '';
      };
    };
in
{
  renderSentryControlMappingTable = wrapPythonScript {
    name = "renderSentryControlMappingTable";
    pythonScript = "from scripts import render_queries_as_a_table; render_queries_as_a_table()";
  };
}

