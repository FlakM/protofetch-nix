{ lib }:

tomlFile:
let
  contents = builtins.readFile tomlFile;
  parsed = builtins.fromTOML contents;

  reservedKeys = [ "name" "description" "proto_out_dir" ];

  name = parsed.name or (throw "protofetch.toml must have a 'name' field");
  proto_out_dir = parsed.proto_out_dir or "proto";
  description = parsed.description or null;

  dependencies = lib.filterAttrs (k: _: !(builtins.elem k reservedKeys)) parsed;
in
{
  inherit name proto_out_dir description dependencies;
}
