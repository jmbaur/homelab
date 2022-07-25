inputs: with inputs; builtins.listToAttrs (builtins.map
  (system: {
    name = system;
    value = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
  })
  flake-utils.lib.defaultSystems)
