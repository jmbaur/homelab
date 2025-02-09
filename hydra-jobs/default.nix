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
mapAttrs (system: _: listToAttrs nixosConfigurations.${system}) inputs.self.legacyPackages
