inputs:

(builtins.mapAttrs (_: nixosConfig: {
  inherit (nixosConfig.config.system.build) toplevel recoveryImage;
}) inputs.self.nixosConfigurations)
// inputs.self.packages
// inputs.self.checks
