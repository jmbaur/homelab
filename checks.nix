inputs:
inputs.nixpkgs.lib.mapAttrs
  (_: pkgs: (pkgs.callPackages ./tests/image.nix { }) // { })
  inputs.self.legacyPackages
