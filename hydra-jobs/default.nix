inputs:

let
  inherit (inputs.nixpkgs.lib)
    filterAttrs
    flatten
    listToAttrs
    mapAttrs
    mapAttrsToList
    systems
    zipAttrs
    ;

  nixosConfigurations = zipAttrs (
    mapAttrsToList (
      name:
      { config, ... }:
      {
        "${config.nixpkgs.buildPlatform.system}" = [
          {
            name = "${name}-toplevel";
            value = config.system.build.toplevel;
          }
          {
            name = "${name}-recovery";
            value = config.system.build.recoveryImage;
          }
        ];
      }
    ) inputs.self.nixosConfigurations
  );
in
mapAttrs
  (
    system: _:
    listToAttrs (flatten (nixosConfigurations.${system} or [ ]))
    //
      # TODO(jared): use _hydraAggregate to gate nixosConfigurations on checks
      inputs.self.checks.${system}
  )
  # Filter out non-linux platforms, since we only build on linux
  (filterAttrs (system: _: (systems.elaborate system).isLinux) inputs.self.legacyPackages)
