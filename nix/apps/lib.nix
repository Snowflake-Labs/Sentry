{ pkgs, self', ... }:
let
  inherit (pkgs.lib) pipe mapAttrs;
in
rec {
  /**
    Wrapper around writeShellApplication that also sets description and mainProgram.
  */
  mkProgram =
    {
      description,
      name,
      text,
      runtimeInputs ? [ ],
      ...
    }:
    (pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text =
        # Silence pushd/popd for all scripts
        ''
          pushd () {
            command pushd "$@" > /dev/null
          }

          popd () {
            # popd is not passing arguments
            command popd > /dev/null
          }
        ''
        + text;
    }).overrideAttrs
      {
        meta = {
          # Description is used for devshell commands
          inherit description;
          # mainProgram is needed, otherwise calls to getExe emit a warning
          mainProgram = name;
        };
      };

  /**
    The pipeline to import a file, apply whatever arguments are needed to generate the scripts and ultimately apply mkProgram to properly generate derivations.
  */
  importPipeline =
    file:
    pipe file [
      builtins.import
      (
        x:
        x {
          inherit pkgs wrapPythonScript;
          inherit (self'.packages) snowcli;
        }
      )
      (mapAttrs (k: v: mkProgram (v // { name = k; })))
    ];

  /**
    Wraps python script with `uv` boilerplate.
  */
  wrapPythonScript =
    pythonScript:
    # bash
    ''
      function exit_trap(){
        popd
        popd
      }

      trap exit_trap EXIT # go back to original dir regardless of the exit codes

      pushd "''${PRJ_ROOT:-$(git rev-parse --show-toplevel)}"

      source ./.venv/bin/activate

      pushd "src"

      python -c "${pythonScript}"
    '';
}
