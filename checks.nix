inputs:

# The tests import self.nixosModules.default, which sets the overlay at
# self.overlays.default, so we don't reuse the pkgs from legacyPackages and
# instead use pkgs from nixpkgs directly.
builtins.listToAttrs (
  map (system: {
    name = system;
    value =
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in
      (pkgs.callPackages ./tests/image.nix { inherit inputs; })
      // {
        desktop = pkgs.callPackage ./tests/desktop.nix { inherit inputs; };
        wgNetwork = pkgs.callPackage ./tests/wg-network.nix { inherit inputs; };
      };
  }) (builtins.attrNames inputs.self.legacyPackages)
)
