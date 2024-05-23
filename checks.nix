inputs:
inputs.nixpkgs.lib.mapAttrs (
  _: pkgs:
  (pkgs.callPackages ./tests/image.nix { inherit inputs; })
  // {
    desktop = pkgs.callPackage ./tests/desktop.nix { inherit inputs; };
  }
) inputs.self.legacyPackages
