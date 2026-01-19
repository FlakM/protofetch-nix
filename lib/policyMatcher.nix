{ lib }:

rec {
  matchPolicy = policy: path:
    let
      normalizedPath = if lib.hasPrefix "/" path then path else "/${path}";
    in
    if lib.hasPrefix "re://" policy then
      matchRegex (lib.removePrefix "re://" policy) normalizedPath
    else if lib.hasSuffix "/*" policy then
      matchPrefix (lib.removeSuffix "/*" policy) normalizedPath
    else if lib.hasPrefix "*/" policy && lib.hasSuffix "/*" (lib.removePrefix "*/" policy) then
      matchContains (lib.removeSuffix "/*" (lib.removePrefix "*/" policy)) normalizedPath
    else
      matchExact policy normalizedPath;

  matchRegex = pattern: path:
    builtins.match pattern path != null;

  matchPrefix = prefix: path:
    lib.hasPrefix prefix path;

  matchContains = substr: path:
    lib.hasInfix substr path;

  matchExact = policy: path:
    let
      normalizedPolicy = if lib.hasPrefix "/" policy then policy else "/${policy}";
    in
    path == normalizedPolicy || lib.hasPrefix "${normalizedPolicy}/" path;

  matchesAnyPolicy = policies: path:
    policies == [] || builtins.any (p: matchPolicy p path) policies;

  shouldInclude = { allow_policies ? [], deny_policies ? [] }: path:
    let
      allowed = allow_policies == [] || matchesAnyPolicy allow_policies path;
      denied = matchesAnyPolicy deny_policies path;
    in
    allowed && !denied;
}
