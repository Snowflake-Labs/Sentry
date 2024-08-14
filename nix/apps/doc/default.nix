{ pkgs, wrapPythonScript, ... }:
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
