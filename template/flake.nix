{
  description = "Project using protofetch-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    protofetch-nix.url = "github:coralogix/protofetch-nix";
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
        };

        default = self.packages.${system}.vendored-protos;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.protobuf ];
        PROTO_PATH = self.packages.${system}.vendored-protos;
      };
    };
}
