inputs:

let
  inherit (inputs.nixpkgs.lib)
    const
    filterAttrs
    flip
    hasSuffix
    mapAttrs
    optionalAttrs
    recursiveUpdate
    systems
    ;
  isLinux = system: (systems.elaborate system).isLinux;
  onlyLinuxOutput = filterAttrs (flip (const isLinux));
in
# TODO(jared): put nixos configurations in their own attrset
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
// {
  # The stub home configuration is not impure
  homeConfigurations = filterAttrs (const (drv: isLinux drv.system)) (
    mapAttrs (const (homeConfig: homeConfig.activationPackage)) (
      filterAttrs (flip (const (hasSuffix "-stub"))) inputs.self.homeConfigurations
    )
  );
}
