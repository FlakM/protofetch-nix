{ lib, parseProtofetchLock, parseProtofetchToml, mkFetchProtofetchDep, policyMatcher }:

{
  protofetchToml,
  protofetchLock,
  extraDeps ? {},
  pkgs ? null,
  forceSsh ? false,
}:
let
  toml = parseProtofetchToml protofetchToml;
  lockedDeps = parseProtofetchLock protofetchLock;
  fetchProtofetchDep = mkFetchProtofetchDep { inherit forceSsh; };

  fetchedDeps = builtins.listToAttrs (map (dep:
    let
      rules = toml.dependencies.${dep.name} or {};
      src = fetchProtofetchDep dep;
      content_roots = rules.content_roots or [ "/" ];
      allow_policies = rules.allow_policies or [];
      deny_policies = rules.deny_policies or [];
    in {
      name = dep.name;
      value = {
        inherit src content_roots allow_policies deny_policies;
        depInfo = dep;
      };
    }
  ) lockedDeps);

  allDeps = fetchedDeps // (builtins.mapAttrs (name: src: {
    inherit src;
    content_roots = [ "/" ];
    allow_policies = [];
    deny_policies = [];
    depInfo = { inherit name; };
  }) extraDeps);

  copyScript = lib.concatMapStrings (name:
    let
      dep = allDeps.${name};
      roots = dep.content_roots;
      allowPolicies = dep.allow_policies;
      denyPolicies = dep.deny_policies;

      copyRoot = root:
        let
          srcPath =
            if root == "/" || root == ""
            then "${dep.src}"
            else "${dep.src}${root}";
        in ''
          if [ -d "${srcPath}" ]; then
            find "${srcPath}" -name '*.proto' -type f | while read -r protoFile; do
              relPath="''${protoFile#${srcPath}/}"
              ${lib.optionalString (allowPolicies != [] || denyPolicies != []) ''
              # Policy filtering
              shouldInclude=true
              ${lib.optionalString (allowPolicies != []) ''
              shouldInclude=false
              ${lib.concatMapStrings (policy: ''
              if [[ "/$relPath" == ${lib.escapeShellArg policy}* ]] || [[ "/$relPath" == ${lib.escapeShellArg policy} ]]; then
                shouldInclude=true
              fi
              '') allowPolicies}
              ''}
              ${lib.concatMapStrings (policy: ''
              if [[ "/$relPath" == ${lib.escapeShellArg policy}* ]] || [[ "/$relPath" == ${lib.escapeShellArg policy} ]]; then
                shouldInclude=false
              fi
              '') denyPolicies}
              if [ "$shouldInclude" = "false" ]; then
                continue
              fi
              ''}
              destDir="$out/$(dirname "$relPath")"
              mkdir -p "$destDir"
              cp "$protoFile" "$destDir/"
            done
          fi
        '';
    in
    lib.concatMapStrings copyRoot roots
  ) (builtins.attrNames allDeps);
in
if pkgs != null then
  pkgs.runCommand "protofetch-vendor-${toml.name}" {
    passthru = {
      inherit toml lockedDeps allDeps;
      protoOutDir = toml.proto_out_dir;
    };
  } ''
    mkdir -p $out
    ${copyScript}
    echo "Vendored ${toString (builtins.length (builtins.attrNames allDeps))} protofetch dependencies"
  ''
else
  {
    inherit toml lockedDeps allDeps copyScript;
    __functor = self: pkgs': self // {
      vendored = (import ./vendorProtofetchDeps.nix {
        inherit lib parseProtofetchLock parseProtofetchToml mkFetchProtofetchDep policyMatcher;
      }) {
        inherit protofetchToml protofetchLock extraDeps forceSsh;
        pkgs = pkgs';
      };
    };
  }
