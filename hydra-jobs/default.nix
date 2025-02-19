inputs:

let
  inherit (inputs.nixpkgs.lib)
    flatten
    listToAttrs
    mapAttrs
    mapAttrsToList
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
mapAttrs (
  system: _:
  listToAttrs (flatten (nixosConfigurations.${system} or [ ]))
  //
    # TODO(jared): use _hydraAggregate to gate nixosConfigurations on checks
    inputs.self.checks.${system}
) inputs.self.legacyPackages
