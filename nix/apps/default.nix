{ pkgs, self', ... }:
let
  inherit (pkgs.lib) pipe mapAttrs;

  /**
    Wrapper around writeShellApplication that also sets description and mainProgram.
  */
  mkProgram =
    { description
    , name
    , text
    , runtimeInputs ? [ ]
    , ...
    }:
    (pkgs.writeShellApplication { inherit name text runtimeInputs; }).overrideAttrs {
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
    file: applicationFunction:
    pipe file [
      builtins.import
      applicationFunction
      (mapAttrs (k: v: mkProgram (v // { name = k; })))
    ];
in
{
  # Deployment models
  localStreamlit = pipe ./local-streamlit [
    builtins.import
    (x: x { inherit pkgs; })
    (mapAttrs (k: v: mkProgram (v // { name = k; })))
  ];
  sis = importPipeline ./sis (
    x:
    x {
      inherit pkgs;
      inherit (self'.packages) snowcli;
    }
  );

  # import ./local-streamlit { inherit pkgs mkProgram; };
  # nativeAppApps = import ./native-app { };
  # gitApps = import ./git { };
  # sprocApps = import ./sprocs { };

  # docApps = import ./doc { };
}
