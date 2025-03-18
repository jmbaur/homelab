inputs:

inputs.nixpkgs.lib.mapAttrs (_: pkgs: {
  jaredHomeEnvironment = pkgs.callPackage ./jared-home-environment { };
}) inputs.self.legacyPackages
