inputs:

let
  inherit (inputs.nixpkgs.lib)
    const
    filterAttrs
    flip
    mapAttrs
    ;
in

mapAttrs (flip const (
  name:
  inputs.mixos.lib.mixosSystem {
    modules = [ ./${name} ];
  }
)) (filterAttrs (const (entryType: entryType == "directory")) (builtins.readDir ./.))
