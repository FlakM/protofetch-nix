# Test script - run with: nix eval -f test.nix
let
  nixpkgs = import <nixpkgs> {};
  lib = nixpkgs.lib;

  protofetch = import ./lib { inherit lib; };

  permissionsServicePath = /home/flakm/programming/coralogix/permissions-service;

  lockFile = permissionsServicePath + "/model/protofetch.lock";
  tomlFile = permissionsServicePath + "/model/protofetch.toml";

  parsedLock = protofetch.parseProtofetchLock lockFile;
  parsedToml = protofetch.parseProtofetchToml tomlFile;
in
{
  lockDependencyCount = builtins.length parsedLock;
  lockDependencyNames = map (d: d.name) parsedLock;
  tomlName = parsedToml.name;
  tomlDependencies = builtins.attrNames parsedToml.dependencies;

  firstDep = builtins.head parsedLock;
}
