{ pkgs, ... }:
let
  /**
    Wraps python script with poetry boilerplate.
  */
  wrapPythonScript =
    pythonScript:
    # bash
    ''
      # halt and catch fire if poetry is not available
      command -v poetry >/dev/null 2>&1 || { echo >&2 "poetry binary not available in PATH; exiting"; exit 1; }

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
in
{
  mkDoc = {
    text =
      # bash
      ''
        function exit_trap(){
          popd
        }
        trap exit_trap EXIT # go back to original dir regardless of the exit codes

        pushd "''${PRJ_ROOT:-$(git rev-parse --show-toplevel)}/docs"

        mdbook build
      '';
    runtimeInputs = [
      pkgs.mdbook
      pkgs.mdsh
    ];
    description = "Main app to render the documentation";
  };

  # Can be used locally to continuously rebuild and serve the doc
  # serveDoc
  serve = {
    text = ''
      function exit_trap(){
        popd
      }
      trap exit_trap EXIT # go back to original dir regardless of the exit codes

      pushd "''${PRJ_ROOT:-$(git rev-parse --show-toplevel)}/docs"

      mdbook serve
    '';
    description = "Serve documentation locally";
  };

  # Render individual components
  mkSprocDocs = {
    text =
      # python
      wrapPythonScript "from scripts import render_stored_procedures; render_stored_procedures()";
    description = "Render stored procedure documentation to stdout";
  };
  renderSentryControlMappingTable = {
    text =
      # python
      wrapPythonScript "from scripts import render_queries_as_a_table; render_queries_as_a_table()";
    description = "Render the Sentry control mapping table to stdout";
  };
}
