inputs:
inputs.nixpkgs.lib.mapAttrs (
  _: pkgs:
  (pkgs.callPackages ./tests/image.nix { inherit inputs; })
  // {
    normal-user = pkgs.callPackage ./tests/normal-user.nix { inherit inputs; };
  }
) inputs.self.legacyPackages
