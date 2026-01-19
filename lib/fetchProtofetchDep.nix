{ lib }:

{ name, url, protocol ? null, commit_hash, revision ? null, branch ? null, ... }:
let
  # url format from protofetch: "github.com/org/repo"
  # Split into forge and path
  parts = lib.splitString "/" url;
  forge = builtins.head parts;
  path = lib.concatStringsSep "/" (builtins.tail parts);

  gitUrl =
    if protocol == "ssh" then
      "git@${forge}:${path}.git"
    else
      "https://${url}";
in
builtins.fetchGit {
  url = gitUrl;
  rev = commit_hash;
  allRefs = true;
}
