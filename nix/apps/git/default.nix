{ wrapPythonScript, snowcli, ... }:
let
  runtimeInputs = [ snowcli ];
  repoRef = "https://github.com/Snowflake-Labs/Sentry";
in
{
  setUp = {
    text =
      #bash
      ''
        LABEL=$(git rev-parse --short HEAD)
        # Append '-dirty' if unstaged files
        test -z "$(git status --porcelain)" || LABEL="$LABEL-dirty"
        snow sql --filename ${./setup.sql} --variable "repo=${repoRef}" --variable "rev=$LABEL"
      '';
    inherit runtimeInputs;
    description = "Set up git integration and repository";
  };

  mkSingleCreateSprocFile = {
    text = wrapPythonScript "from scripts import render_sprocs_as_single_file; render_sprocs_as_single_file()";
    description = "Generate create_all.sql file that creates all sprocs";
  };

  runCreateAll = {
    text =
      #bash
      ''
        snow sql --query "EXECUTE IMMEDIATE FROM @sentry_git.public.sentry_repo/branches/main/deployment_models/git-repository/create_all.sql"
      '';
    inherit runtimeInputs;
    description = "Run create_all.sql as EXECUTE IMMEDIATE FROM";
  };
  runOneQuery = {
    text =
      #bash
      ''
        snow sql --query "EXECUTE IMMEDIATE FROM @sentry_git.public.sentry_repo/branches/main/src/queries/auth_by_method/auth_by_method.sql"
      '';
    inherit runtimeInputs;
    description = "Run single query as EXECUTE IMMEDIATE FROM";
  };

  tearDown = {
    text =
      #bash
      ''
        echo "This procedure will destroy objects created during setUp."
        echo "It assumes that the objects to be removed were created from the same Sentry version."
        echo "Some objects may remain"

        snow sql --filename ${./teardown.sql}
      '';
    inherit runtimeInputs;
    description = "Tear down git integration and repository";
  };
}
