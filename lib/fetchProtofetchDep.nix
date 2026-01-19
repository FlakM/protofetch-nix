{ lib }:

{ forceSsh ? false }:

{ name, url, protocol ? null, commit_hash, revision ? null, branch ? null, ... }:
let
  parts = lib.splitString "/" url;
  forge = builtins.head parts;
  path = lib.concatStringsSep "/" (builtins.tail parts);

  gitUrl =
    if forceSsh || protocol == "ssh" then
      "git@${forge}:${path}.git"
    else
      "https://${url}";
in
builtins.fetchGit {
  url = gitUrl;
  rev = commit_hash;
  allRefs = true;
}
