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
}
