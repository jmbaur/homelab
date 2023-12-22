inputs:
inputs.nixpkgs.lib.mapAttrs
  (_: pkgs: pkgs.nixpkgs-fmt)
  inputs.self.legacyPackages
