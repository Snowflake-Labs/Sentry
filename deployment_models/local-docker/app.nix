/**
  Contains Nix flake application to automate running Streamlit in a local container.

  This file is not necessary for running Streamlit in local Docker container in a generic environment, it's only used when the project environment is managed through nix.
*/
{ writeShellApplication }:
writeShellApplication {
  name = "local-docker-build-and-run-non-nix";
  runtimeInputs = [ ]; # NOTE: docker should be installed independently
  text = ''
    # halt and catch fire if docker is not available
    command -v docker >/dev/null 2>&1 || { echo >&2 "docker binary not available in PATH; exiting"; exit 1; }
    function exit_trap(){
      popd
    }
    trap exit_trap EXIT # go back to original dir regardless of the exit codes
    IMAGE_TAG="sentry:latest"

    pushd "$PRJ_ROOT"
    # Build using the standard docker tools
    docker build . -t "$IMAGE_TAG" -f deployment_models/local-docker/Dockerfile
    # Run with mounting the streamlit secrets into the app directory
    docker run --rm `# clean up container after run`\
               --mount type=bind,source="$PRJ_ROOT"/.streamlit,target=/app/.streamlit,readonly `# mount the secrets into the container` \
               --publish-all `# assign random ports` \
               "$IMAGE_TAG"
  '';
}
