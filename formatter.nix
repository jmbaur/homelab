inputs:
inputs.nixpkgs.lib.mapAttrs
  (_: pkgs: pkgs.nixfmt-rfc-style)
  inputs.self.legacyPackages
