{ pkgs, snowcli, ... }:
let
  runtimeInputs = [ snowcli ];
  nativeAppDir = "$PRJ_ROOT/deployment_models/native-app/";
  appVersion = "v1"; # TODO: make first-order object
in
{
  # Apps are self-contained => no setup needed
  # setUp = {
  #   text = "";
  #   inherit runtimeInputs;
  #   description = "Set up a dedicated user and deploy the application.";
  # };

  run = {
    text =
      # bash
      ''
        function exit_trap(){
          popd
        }
        trap exit_trap EXIT # go back to original dir regardless of the exit codes
        # Change into proper directory
        PRJ_ROOT=$(git rev-parse --show-toplevel)
        pushd "${nativeAppDir}"

        snow app run "$@"
      '';
    inherit runtimeInputs;
    description = "Push the latest version of the Native App and run it in debug mode";
  };

  open = {
    text =
      # bash
      ''
        function exit_trap(){
          popd
        }
        trap exit_trap EXIT # go back to original dir regardless of the exit codes
        # Change into proper directory
        PRJ_ROOT=$(git rev-parse --show-toplevel)
        pushd "${nativeAppDir}"

        snow app open "$@"
      '';
    inherit runtimeInputs;
    description = "Open Native App in browser";
  };

  tearDown = {
    text =
      # bash
      ''
        function exit_trap(){
          popd
        }
        trap exit_trap EXIT # go back to original dir regardless of the exit codes
        # Change into proper directory
        PRJ_ROOT=$(git rev-parse --show-toplevel)
        pushd "${nativeAppDir}"

        snow app teardown "$@"
      '';
    inherit runtimeInputs;
    description = "Tear down the application. See snow app teardown --help for parameters.";
  };

  deployVersion = {
    text =
      # bash
      ''
        # This script forces a standard application name

        function exit_trap(){
          popd
        }
        trap exit_trap EXIT # go back to original dir regardless of the exit codes

        PRJ_ROOT=$(git rev-parse --show-toplevel)

        TARGET="$PRJ_ROOT/target"

        pushd "$PRJ_ROOT" # cd to project root directory

        rm -rf "$TARGET"
        cp -rf "${nativeAppDir}" "$TARGET"
        pushd "$TARGET"/

        # The release should be under "Sentry" package, rather than auto-generated code
        cat >snowflake.local.yml <<EOF
        definition_version: 1
        native_app:
          package:
            name: sentry
        EOF

        # Override manifest.yaml to set the version and git commit dynamically
        yq --in-place --yml-roundtrip '.version.name |= "${appVersion}"' app/manifest.yml

        LABEL=$(git rev-parse --short HEAD)
        # Append '-dirty' if unstaged files
        test -z "$(git status --porcelain)" || LABEL="$LABEL-dirty"
        yq --in-place --yml-roundtrip ".version.label |= \"$LABEL\"" app/manifest.yml

        snow app deploy
        snow app version create "$@" --skip-git-check
      '';
    runtimeInputs = runtimeInputs ++ [
      pkgs.jq
      pkgs.yq
    ];
    description = "Create a new version. Passes args to snowcli.";
  };

  release = {
    text =
      # bash
      ''
        function exit_trap(){
          popd
        }
        trap exit_trap EXIT # go back to original dir regardless of the exit codes

        PRJ_ROOT=$(git rev-parse --show-toplevel)

        TARGET="$PRJ_ROOT/target"

        pushd "$PRJ_ROOT" # cd to project root directory

        rm -rf "$TARGET"
        cp -rf "${nativeAppDir}" "$TARGET"
        pushd "$TARGET"/

        # The release should be under "Sentry" package, rather than auto-generated code
        cat >snowflake.local.yml <<EOF
        definition_version: 1
        native_app:
          package:
            name: sentry
        EOF

        VERSIONS=$(snow app version list --format=json | jq '. |= sort_by(.created_on) | last')
        if [ "$VERSIONS" == "null" ]; then
          echo "Please make sure that a version exists"
        fi

        VERSION=$(echo "$VERSIONS" | jq --raw-output '.version')
        PATCH=$(echo "$VERSIONS" | jq --raw-output '.patch')

        # This is idempotent
        snow sql --query "ALTER APPLICATION PACKAGE SENTRY SET DEFAULT RELEASE DIRECTIVE VERSION = $VERSION PATCH = $PATCH"
      '';
    runtimeInputs = runtimeInputs ++ [ pkgs.jq ];
    description = "Updates the default release directive to the latest version";
  };
}
