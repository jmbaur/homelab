inputs:

let
  inherit (inputs.nixpkgs.lib)
    const
    filterAttrs
    flip
    mapAttrs
    ;
in

mapAttrs (flip (
  const (
    name:
    inputs.mixos.lib.mixosSystem {
      modules = [
        {
          nixpkgs.pkgs = import inputs.nixpkgs {
            localSystem = "x86_64-linux";
            crossSystem = {
              isStatic = false;
              config = "armv7l-unknown-linux-gnueabihf";
              gcc = {
                arch = "armv7-a";
                fpu = "vfpv3-d16";
              };
            };
          };
        }
        ./${name}
      ];
    }
  )
)) (filterAttrs (const (entryType: entryType == "directory")) (builtins.readDir ./.))
