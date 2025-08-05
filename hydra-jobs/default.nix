inputs:

let
  inherit (inputs.nixpkgs.lib) filterAttrs systems;
  onlyLinuxOutput = filterAttrs (system: _: (systems.elaborate system).isLinux);
in
(builtins.mapAttrs (_: nixosConfig: {
  inherit (nixosConfig.config.system.build) toplevel recoveryImage;
}) inputs.self.nixosConfigurations)
// onlyLinuxOutput inputs.self.packages
// onlyLinuxOutput inputs.self.checks
