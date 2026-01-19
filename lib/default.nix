{ lib }:

let
  parseProtofetchLock = import ./parseProtofetchLock.nix { inherit lib; };
  parseProtofetchToml = import ./parseProtofetchToml.nix { inherit lib; };
  fetchProtofetchDep = import ./fetchProtofetchDep.nix { inherit lib; };
  policyMatcher = import ./policyMatcher.nix { inherit lib; };
in
{
  inherit parseProtofetchLock parseProtofetchToml fetchProtofetchDep policyMatcher;

  vendorProtofetchDeps = import ./vendorProtofetchDeps.nix {
    inherit lib parseProtofetchLock parseProtofetchToml fetchProtofetchDep policyMatcher;
  };
}
