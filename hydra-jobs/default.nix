inputs:
inputs.nixpkgs.lib.mapAttrs (_: pkgs: {
  inherit (pkgs) hello;
}) inputs.self.legacyPackages
