inputs:

let
  inherit (inputs.nixpkgs.lib)
    mapAttrs
    listToAttrs
    mapAttrsToList
    zipAttrs
    ;

  nixosConfigurations = zipAttrs (
    mapAttrsToList (
      name:
      { config, ... }:
      {
        "${config.nixpkgs.buildPlatform.system}" = {
          inherit name;
          value = config.system.build.toplevel;
        };
      }
    ) inputs.self.nixosConfigurations
  );
in
mapAttrs (
  system: _:
  listToAttrs (nixosConfigurations.${system} or [ ])
  //
    # TODO(jared): use _hydraAggregate to gate nixosConfigurations on checks
    inputs.self.checks.${system}
) inputs.self.legacyPackages
