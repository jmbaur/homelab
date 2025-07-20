inputs:
inputs.nixpkgs.lib.mapAttrs' (system: pkgs: {
  name = "generic-${system}";
  value = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      inputs.nix-index-database.homeModules.nix-index
      (
        { lib, ... }:
        {
          news.display = "silent";
          home =
            assert (
              lib.assertMsg (builtins.hasAttr "currentTime" builtins) ''
                This home-manager configuration must be evaluated with --impure in order for it to be generic over different hosts.
              ''
            );
            {
              stateVersion = "25.11";
              username = builtins.getEnv "USER";
              homeDirectory = builtins.getEnv "HOME";
            };
        }
      )
      ./generic.nix
    ];
  };
}) inputs.self.legacyPackages
