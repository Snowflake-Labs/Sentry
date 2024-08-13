{ pkgs, snowcli, ... }:
let
  runtimeInputs = [ snowcli ];
in
{
  setUp = {
    text =
      # bash
      ''
        echo "This program will create base set of objects for Sentry SiS application"
        echo "It will not set up specific authentication(key or password) for the 'sentry_app_user' user"
        echo "Please do that in a separate statement"

        snow sql --filename ${./setup.sql} --variable "rev=$(git rev-parse --short HEAD)"

        echo "Setup done. Please make sure to set up authentication for the created user."
        echo "Please refer to https://docs.snowflake.com/en/sql-reference/sql/alter-user for authentication parameters"
      '';
    inherit runtimeInputs;
    description = "Set up a dedicated user and deploy the application.";
  };

  deploy = {
    text =
      # bash
      ''
        # This script deploys the SiS application
        # It does not perform initial setup; this command should be used for continious deployment

        # This block manipulates directory stack to be in the proper dir for dpeloyment
        function exit_trap(){
          popd
        }
        trap exit_trap EXIT # go back to original dir regardless of the exit codes
        # Change into proper directory
        PRJ_ROOT=$(git rev-parse --show-toplevel)
        pushd "$PRJ_ROOT/src"

        # Get application name
        SIS_APP_NAME=$(yq --raw-output ".streamlit.name" ./snowflake.yml)

        # Deploy the application
        # NOTE: the CI variable check prevents the account name from being printed by suppressing all output
        if [ -n "''${CI+x}" ]; then
          exec &>/dev/null
        fi

        # NOTE: The actual location of Streamlit is dictated by snowcli connection properties
        snow streamlit deploy \
          --replace `# replace installed app` \
          --role "$SIS_OWNER_ROLE" `# Streamlit app will be owned by connecting role`\
          "$@" #pass the remainder of parameters to snowcli

        # Share the application with the target role
        snow streamlit share "$SIS_APP_DATABASE.$SIS_APP_SCHEMA.$SIS_APP_NAME" "$SIS_GRANT_TO_ROLE" \
          "$@" #pass the remainder of parameters to snowcli
      '';
    runtimeInputs = runtimeInputs ++ [ pkgs.yq ];
    description = "Deploy the SiS application";
  };

  # Convenience wrapper around get-url that parses teh application name using the environment variables
  open = {
    text =
      # bash
      ''
        # This block manipulates directory stack to be in the proper dir for dpeloyment
        function exit_trap(){
          popd
        }
        trap exit_trap EXIT # go back to original dir regardless of the exit codes
        # Change into proper directory
        PRJ_ROOT=$(git rev-parse --show-toplevel)
        pushd "$PRJ_ROOT/src"

        # Get application name
        SIS_APP_NAME=$(yq --raw-output ".streamlit.name" ./snowflake.yml)

        snow streamlit get-url "$SIS_APP_DATABASE.$SIS_APP_SCHEMA.$SIS_APP_NAME" \
          --open `# open the url in browser` \
          "$@"
      '';
    inherit runtimeInputs;
    description = "Open the deployed app in browser.";
  };

  tearDown = {
    text =
      # bash
      ''
        echo "This procedure will destroy objects created during setUp."
        echo "It assumes that the objects to be removed were created from the same Sentry version."
        echo "Some objects may remain"

        function exit_trap(){
          popd
        }
        trap exit_trap EXIT # go back to original dir regardless of the exit codes
        # Change into proper directory
        PRJ_ROOT=$(git rev-parse --show-toplevel)
        pushd "$PRJ_ROOT/src"

        SIS_APP_NAME=$(yq --raw-output ".streamlit.name" ./snowflake.yml)

        snow streamlit drop "$SIS_APP_DATABASE.$SIS_APP_SCHEMA.$SIS_APP_NAME" "$@"

        snow sql --filename ${./teardown.sql}
      '';
    inherit runtimeInputs;
    description = "Remove artifacts created during setup.";
  };
}
