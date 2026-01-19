{
  description = "Example: vendor protos using local mock files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    protofetch-nix.url = "path:../..";
  };

  outputs = { self, nixpkgs, protofetch-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      protofetch = protofetch-nix.lib;
    in
    {
      packages.${system} = {
        vendored-protos = protofetch.vendorProtofetchDeps {
          protofetchToml = ./protofetch.toml;
          protofetchLock = ./protofetch.lock;
          inherit pkgs;
          extraDeps = {
            mock-protos = ./mock-protos;
          };
        };

        default = self.packages.${system}.vendored-protos;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.protobuf ];
        PROTO_PATH = self.packages.${system}.vendored-protos;
      };
    };
}
