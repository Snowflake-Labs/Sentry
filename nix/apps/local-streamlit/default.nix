{ pkgs, ... }:
{
  setUp = {
    text = ''
      uv sync --all-extras
      echo "Please setup Streamlit secrets are set up."
      echo "For more details, see https://snowflake-labs.github.io/Sentry/guide/installation/local-streamlit.html"
    '';
    runtimeInputs = [ pkgs.uv ];
    description = "Setup the python project.";
  };

  run = {
    text = ''
      uv run streamlit run "$PRJ_ROOT"/src/Authentication.py
    '';
    runtimeInputs = [ pkgs.uv ];
    description = "Run local streamlit";
  };

  tearDown = {
    text = ''
      echo "Please use 'rm -rf .venv' if you want to remove the virtual environment."
      echo "More information here:"
      echo "https://docs.astral.sh/uv/concepts/projects/#project-environments"
    '';
    runtimeInputs = [ pkgs.uv ];
    description = "Remove virtual environment";
  };
}
