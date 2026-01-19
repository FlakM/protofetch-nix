{ lib }:

let
  parseProtofetchLock = import ./parseProtofetchLock.nix { inherit lib; };
  parseProtofetchToml = import ./parseProtofetchToml.nix { inherit lib; };
  mkFetchProtofetchDep = import ./fetchProtofetchDep.nix { inherit lib; };
  fetchProtofetchDep = mkFetchProtofetchDep {};
  policyMatcher = import ./policyMatcher.nix { inherit lib; };
in
{
  inherit parseProtofetchLock parseProtofetchToml fetchProtofetchDep policyMatcher mkFetchProtofetchDep;

  vendorProtofetchDeps = import ./vendorProtofetchDeps.nix {
    inherit lib parseProtofetchLock parseProtofetchToml mkFetchProtofetchDep policyMatcher;
  };
}
