{ pkgs, ... }:
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
        inherit description;
        mainProgram = name;
      };
    };
in
{
  # Deployment models
  localStreamlit = pipe ./local-streamlit [
    builtins.import
    (x: x { inherit pkgs; })
    (mapAttrs (k: v: mkProgram (v // { name = k; })))
  ];
  # sis = import ./sis { inherit pkgs; };
  # import ./local-streamlit { inherit pkgs mkProgram; };
  # nativeAppApps = import ./native-app { };
  # gitApps = import ./git { };
  # sprocApps = import ./sprocs { };

  # docApps = import ./doc { };
}
