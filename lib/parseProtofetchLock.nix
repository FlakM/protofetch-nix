{ lib }:

lockFile:
let
  contents = builtins.readFile lockFile;
  lock = builtins.fromTOML contents;
in
assert lock.version or 0 == 2 || throw "Unsupported protofetch.lock version: ${toString (lock.version or "missing")}. Expected version 2.";
lock.dependencies or []
