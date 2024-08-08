{
  description = "Description for the project";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs.follows = "nixpkgs-stable";
    snowcli = {
      url = "github:sfc-gh-vtimofeenko/snowcli-nix-flake";

      inputs = {
        nixpkgs-unstable.follows = "nixpkgs-unstable";
        nixpkgs.follows = "nixpkgs-unstable";
        # development
        devshell.follows = "devshell";
        pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { flake-parts-lib, ... }:
      let
        inherit (flake-parts-lib) importApply;
      in
      {
        imports = [
          inputs.devshell.flakeModule
          inputs.pre-commit-hooks-nix.flakeModule
          inputs.treefmt-nix.flakeModule
          (importApply ./linters.nix { inherit flake-parts-lib; })
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        perSystem =
          { config
          , inputs'
          , pkgs
          , self'
          , ...
          }:
          let
            inherit (pkgs.lib)
              pipe
              mapAttrs
              attrValues
              listToAttrs
              flatten
              mapAttrsToList
              splitString
              head
              ;

            # This attrset will be used in two places:
            # * Apps
            # * Devshell scripts that effectively run apps
            apps = pipe ./nix/apps [
              builtins.import
              (x: x { inherit pkgs; }) # apply pkgs
              # Turn nested attribute sets with packages into apps, prepending the category prefix
              (mapAttrs (
                k: v: # This is the outer attrset, k = "sis", v = "import ./sis { inherit pkgs;}"
                  pipe v [
                    (mapAttrs (
                      # This is the inner attrset, k' = setup, v' = {whatever code}
                      k': v': {
                        name = "${k}-${k'}";
                        value = {
                          type = "app";
                          program = v';
                        };
                      }
                    ))
                    attrValues
                  ]
              ))
              # Turn everything into a top-level attrset
              attrValues
              flatten
              listToAttrs
            ];
          in
          {
            packages = rec {
              # This package is used to pin and propagate snowcli version
              snowcli = inputs'.snowcli.packages.snowcli-2x;

              # TODO: Replace with nix package in #11
              # For now specify snowcli so `nix flake check` passes
              default = snowcli;
            };

            inherit apps;

            # Development configuration
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
              projectRootFile = "flake.nix";
              # Vendored modules are explicitly excluded from formatter to stay as close to upstream as possible
              settings.global.excludes = [ "./src/vendored/*" ];
            };

            devShells.pre-commit = config.pre-commit.devShell;
            devshells.default = {
              env = [ ];
              # Construct commands from apps, using program description as command help
              commands = mapAttrsToList
                (k: v: {
                  name = k;
                  help = v.program.meta.description;
                  category = pipe k [
                    (splitString "-")
                    head
                  ];
                  command = "nix run $PRJ_ROOT#${k}";
                })
                apps;
              packages = attrValues {
                inherit (pkgs)
                  jc
                  jq
                  mdsh
                  mdbook
                  ;
                inherit (self'.packages) snowcli;
              };
            };
          };
        # flake = { };
      }
    );
}
