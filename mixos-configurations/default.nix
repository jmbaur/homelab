inputs:

let
  inherit (inputs.nixpkgs.lib)
    const
    filterAttrs
    flip
    mapAttrs
    mkOption
    types
    ;
in

mapAttrs (flip (
  const (
    name:
    inputs.mixos.lib.mixosSystem {
      modules = [
        # Options for all mixos configurations within this flake.
        {
          options.custom.hydraJobs = mkOption {
            type = types.listOf types.str;
            default = [ "toplevel" ];
            description = ''
              Attributes of `system.build` to build in CI. Anything beyond
              the toplevel is specific to the hardware a configuration runs
              on, such as images used to update or install the machine.
            '';
          };
        }
        (import ./${name} inputs)
      ];
    }
  )
)) (filterAttrs (const (entryType: entryType == "directory")) (builtins.readDir ./.))
