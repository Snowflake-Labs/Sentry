{ pkgs, self', ... }:
let
  inherit (import ./lib.nix { inherit pkgs self'; }) importPipeline;
in
{
  # Deployment models
  localStreamlit = importPipeline ./local-streamlit;
  sis = importPipeline ./sis;
  localDocker = importPipeline ./local-docker;
  nativeApp = importPipeline ./native-app;

  doc = importPipeline ./doc;

  git = importPipeline ./git;
  # sprocApps = import ./sprocs { };

  # docApps = import ./doc { };
}
