{ pkgs, ... }:
{

  setUp = {
    text =
      # bash
      ''
        # halt and catch fire if docker is not available
        command -v docker >/dev/null 2>&1 || { echo >&2 "docker binary not available in PATH; exiting"; exit 1; }

        echo "docker seems to be installed, exiting"
        exit 0
      '';
    description = "Make sure docker is installed.";
  };

  run = {
    text =
      # bash
      ''
        # halt and catch fire if docker is not available
        command -v docker >/dev/null 2>&1 || { echo >&2 "docker binary not available in PATH; exiting"; exit 1; }


        function exit_trap(){
          popd
        }
        trap exit_trap EXIT # go back to original dir regardless of the exit codes


        IMAGE_TAG="sentry:$(git rev-parse --short HEAD)"

        pushd "$PRJ_ROOT"
        # Build using the standard docker tools
        docker build . -t "$IMAGE_TAG" -f deployment_models/local-docker/Dockerfile
        # Run with mounting the streamlit secrets into the app directory
        docker run --rm `# clean up container after run`\
                   --mount type=bind,source="$PRJ_ROOT"/.streamlit,target=/app/.streamlit,readonly `# mount the secrets into the container` \
                   --publish-all `# assign random ports` \
                   "$IMAGE_TAG"
      '';
    description = "Run Sentry in local docker container";
  };

  open = {
    text =
      # bash
      ''
        # pipefail should take care of error handling here
        command -v xdg-open >/dev/null 2>&1 && OPEN_CMD="xdg-open" || OPEN_CMD="open"

        "$OPEN_CMD" "http://$(docker ps --format "json" | jq --raw-output '. | select(.Image | contains("sentry")) | .Ports | split("-") | .[0]')"
      '';
    runtimeInputs = [ pkgs.jq ];
    description = "Open Sentry in browser";
  };

  tearDown = {
    text = "echo 'Use docker prune to clean up images/volumes/containers'";
    description = "Provides instructions to clear Sentry artifacts";
  };

}
