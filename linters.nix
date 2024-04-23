/**
  [Pre-commit][1] and [treefmt][2] configuration for the project.

  For information on the fields, see flake-parts documentation:

  - pre-commit: https://flake.parts/options/pre-commit-hooks-nix
  - treefmt: https://flake.parts/options/treefmt-nix

  This file is effectively a flake-module for flake-parts terminology, thus
  it's structured as a module producing function of `flake-parts-lib`.

  [1]: https://pre-commit.com/
  [2]: https://github.com/numtide/treefmt
*/
{ flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
_: {
  options.perSystem = mkPerSystemOption (
    { config, ... }:
    {
      config = {
        treefmt = {
          programs = {
            nixpkgs-fmt.enable = true;
            deadnix = {
              enable = true;
              no-lambda-arg = true;
              no-lambda-pattern-names = true;
              no-underscore = true;
            };
            statix.enable = true;
            isort = {
              enable = true;
              profile = "black";
            };
            ruff = {
              enable = true;
              format = true;
            };
          };
          # Vendored modules are explicitly excluded from formatter to stay as close to upstream as possible
          settings.global.excludes = [ "./src/vendored/*" ];
        };

        pre-commit.settings =
          # let
          #   mdshFiles = "^src/queries/.*";
          # in
          {
            hooks = {
              treefmt.enable = true;
              treefmt.package = config.treefmt.build.wrapper;
              deadnix = {
                enable = true;
                settings.edit = true;
              };
              statix = {
                enable = true;
                settings = {
                  ignore = [ ".direnv/" ];
                  format = "stderr";
                };
              };
              markdownlint.enable = true;
              markdownlint.settings.configuration = {
                MD041 = false; # Disable "first line should be a heading check"
                MD010.code_blocks = false; # Do not check for hard tabs in code blocks
                MD013.code_blocks = false; # Do not check for long lines in code blocks
                MD025 = false; # Disable "multiple top-level headings in the same document"
              };
              ruff.enable = true;

              # TODO: restore this, fail if output differs.
              # run-mdsh-for-git-instructions = {
              #   enable = true;
              #   description = "Call mdsh to auto-generate the sproc instructions";
              #   entry = "${getExe pkgs.mdsh} --inputs ./deployment_models/git-repository/README.md --frozen";
              #   fail_fast = true;
              #   pass_filenames = false;
              #   files = mdshFiles;
              # };
              # generate-sql-file-to-create-all-sprocs = {
              #   enable = true;
              #   description = "Generate create_all.sql for mass SPROC install.";
              #   entry = "nix run .#mkSingleCreateSprocFile > ./deployment_models/git-repository/create_all.sql";
              #   fail_fast = true;
              #   pass_filenames = false;
              #   files = mdshFiles;
              # };
            };
            excludes = [ "^src/vendored" ];
          };
      };
    }
  );
}
