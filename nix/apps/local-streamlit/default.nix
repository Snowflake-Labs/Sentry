{ pkgs, ... }:
{
  setUp = {
    text = ''
      poetry install
      echo "Please setup Streamlit secrets are set up."
      echo "For more details, see https://snowflake-labs.github.io/Sentry/guide/installation/local-streamlit.html"
    '';
    runtimeInputs = [ pkgs.poetry ];
    description = "Setup the python project.";
  };

  run = {
    text = ''
      poetry run streamlit run "$PRJ_ROOT"/src/Authentication.py
    '';
    runtimeInputs = [ pkgs.poetry ];
    description = "Run local streamlit";
  };

  tearDown = {
    text = ''
      echo "Please use poetry env remove if you want to remove the virtual environment."
      echo "More information here:"
      echo "https://python-poetry.org/docs/managing-environments/#deleting-the-environments"
    '';
    runtimeInputs = [ pkgs.poetry ];
    description = "Remove virtual environment";
  };
}
