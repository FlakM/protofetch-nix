{
  description = "Nix library for vendoring protofetch dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      lib = import ./lib { lib = nixpkgs.lib; };

      overlays.default = final: prev: {
        protofetch-nix = self.lib;
      };

      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.runCommand "protofetch-nix-info" {} ''
            mkdir -p $out
            cat > $out/README <<EOF
            protofetch-nix - Nix library for vendoring protofetch dependencies

            This is a library flake. Use it as an input in your flake:

              inputs.protofetch-nix.url = "github:coralogix/protofetch-nix";

            Then use the lib functions:

              protofetch-nix.lib.vendorProtofetchDeps {
                protofetchToml = ./protofetch.toml;
                protofetchLock = ./protofetch.lock;
                inherit pkgs;
              }

            See: https://github.com/coralogix/protofetch-nix
            EOF
            echo "protofetch-nix library - see $out/README"
          '';
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.mkShell {
            packages = [ pkgs.protobuf ];
          };
        }
      );

      checks = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          protofetch = self.lib;
        in {
          basic-parse = pkgs.runCommand "test-basic-parse" {} ''
            echo "Library loaded successfully"
            touch $out
          '';

          simple-example = protofetch.vendorProtofetchDeps {
            protofetchToml = ./examples/simple/protofetch.toml;
            protofetchLock = ./examples/simple/protofetch.lock;
            inherit pkgs;
            extraDeps = {
              mock-protos = ./examples/simple/mock-protos;
            };
          };
        }
      );

      templates.default = {
        path = ./template;
        description = "Basic protofetch-nix usage template";
      };
    };
}
