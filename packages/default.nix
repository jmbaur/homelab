inputs:

inputs.nixpkgs.lib.mapAttrs (_: pkgs: {
  jaredHomeEnvironment = pkgs.callPackage ./jared-home-environment { };
  designs = pkgs.callPackage ./designs { };
}) inputs.self.legacyPackages
