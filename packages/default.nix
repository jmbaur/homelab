inputs:

inputs.nixpkgs.lib.mapAttrs (
  _: pkgs:
  pkgs.lib.packagesFromDirectoryRecursive {
    inherit (pkgs) callPackage;
    directory = ./by-name;
  }
) inputs.self.legacyPackages
