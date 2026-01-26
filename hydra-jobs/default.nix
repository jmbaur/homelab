inputs:

let
  inherit (inputs.nixpkgs.lib)
    filterAttrs
    optionalAttrs
    recursiveUpdate
    systems
    ;
  onlyLinuxOutput = filterAttrs (system: _: (systems.elaborate system).isLinux);
in
(builtins.mapAttrs (
  _: nixosConfig:
  recursiveUpdate
    {
      inherit (nixosConfig.config.system.build) toplevel;
    }
    (
      optionalAttrs nixosConfig.config.custom.recovery.enable {
        inherit (nixosConfig.config.system.build) recoveryImage;
      }
    )
) inputs.self.nixosConfigurations)
// recursiveUpdate (onlyLinuxOutput inputs.self.packages) (onlyLinuxOutput inputs.self.checks)
