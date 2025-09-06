{ lib }:
let
  inherit (lib)
    concatMapAttrs
    concatStringsSep
    genList
    listToAttrs
    substring
    ;
in
concatMapAttrs
  (
    name: numIPs:
    listToAttrs (
      genList (
        x:
        let
          name' = "${name}-${toString x}";
        in
        # Pulls 64 bits from a hash of args in order to create an IPv6 interface ID.
        let
          hash = builtins.hashString "sha256" name';
        in
        # Prefix with two colons to indicate these are the last 64 bits
        {
          name = name';
          value = "::" + (concatStringsSep ":" (genList (x: substring (x * 4) 4 hash) 4));
        }
      ) numIPs
    )
  )
  {
    broccoli = 1;
    pumpkin = 1;
  }
