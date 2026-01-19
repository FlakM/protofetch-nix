# protofetch-nix

A Nix library for declaratively fetching protobuf dependencies using [protofetch](https://github.com/coralogix/protofetch) lock files.

Inspired by [crane](https://github.com/ipetkov/crane) for Cargo dependencies.

## Features

- Parse `protofetch.lock` files at Nix evaluation time
- Fetch git dependencies using `builtins.fetchGit`
- Apply content roots and allow/deny policies
- Produce a vendored proto directory for use with protoc

## Usage

### Basic Example

```nix
{
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
      packages.${system}.vendored-protos = protofetch.vendorProtofetchDeps {
        protofetchToml = ./protofetch.toml;
        protofetchLock = ./protofetch.lock;
        inherit pkgs;
      };
    };
}
```

### With Extra Dependencies

```nix
protofetch.vendorProtofetchDeps {
  protofetchToml = ./protofetch.toml;
  protofetchLock = ./protofetch.lock;
  inherit pkgs;
  extraDeps = {
    google-protobuf = pkgs.fetchFromGitHub {
      owner = "protocolbuffers";
      repo = "protobuf";
      rev = "v25.1";
      hash = "sha256-...";
    } + "/src";
  };
}
```

### Using with Rust (tonic/prost)

```nix
{
  packages.${system}.my-service = pkgs.rustPlatform.buildRustPackage {
    pname = "my-service";
    version = "0.1.0";
    src = ./.;
    cargoLock.lockFile = ./Cargo.lock;

    nativeBuildInputs = [ pkgs.protobuf ];

    PROTOC = "${pkgs.protobuf}/bin/protoc";
    PROTO_PATH = self.packages.${system}.vendored-protos;

    preBuild = ''
      export OUT_DIR=$(mktemp -d)
    '';
  };
}
```

## Library Functions

### `vendorProtofetchDeps`

Main entry point. Vendors all protofetch dependencies into a single directory.

**Arguments:**
- `protofetchToml` - Path to `protofetch.toml`
- `protofetchLock` - Path to `protofetch.lock`
- `pkgs` - Nixpkgs instance (for `runCommand`)
- `extraDeps` - (optional) Additional dependencies as `{ name = src; }`

**Returns:** A derivation containing all `.proto` files.

### `parseProtofetchLock`

Parse a `protofetch.lock` file.

```nix
protofetch.parseProtofetchLock ./protofetch.lock
# => [ { name = "dep1"; url = "..."; commit_hash = "..."; } ... ]
```

### `parseProtofetchToml`

Parse a `protofetch.toml` file.

```nix
protofetch.parseProtofetchToml ./protofetch.toml
# => { name = "project"; proto_out_dir = "proto"; dependencies = { ... }; }
```

### `fetchProtofetchDep`

Fetch a single dependency from the lock file.

```nix
protofetch.fetchProtofetchDep {
  name = "my-dep";
  url = "github.com/org/repo";
  protocol = "ssh";
  commit_hash = "abc123...";
}
```

## Private Repositories

For private repositories using SSH, ensure your SSH agent has the appropriate keys loaded:

```bash
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
nix build .#vendored-protos
```

## How It Works

1. `protofetch.lock` is parsed using `builtins.fromTOML`
2. Each dependency is fetched using `builtins.fetchGit` with the locked commit hash
3. Content roots from `protofetch.toml` select which directories to include
4. Allow/deny policies filter which `.proto` files to copy
5. All filtered protos are combined into a single output directory

## License

MIT
