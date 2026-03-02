inputs:
inputs.nixpkgs.lib.concatMapAttrs (
  system: pkgs:
  let
    homeConfiguration =
      {
        stub ? false,
      }:
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          inputs.nix-index-database.homeModules.nix-index
          (
            { lib, ... }:
            {
              news.display = "silent";
              home =
                assert (
                  lib.assertMsg (!stub -> builtins.hasAttr "currentTime" builtins) ''
                    This home-manager configuration must be evaluated with --impure in order for it to be generic over different hosts.
                  ''
                );
                {
                  stateVersion = "26.05";
                  username = if stub then "stub" else builtins.getEnv "USER";
                  homeDirectory = if stub then "/home/stub" else builtins.getEnv "HOME";
                };
            }
          )
          ./generic.nix
        ];
      };
  in
  {
    "generic-${system}" = homeConfiguration { stub = false; };
    "generic-${system}-stub" = homeConfiguration { stub = true; };
  }
) inputs.self.legacyPackages
