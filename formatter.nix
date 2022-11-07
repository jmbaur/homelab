inputs: with inputs; nixpkgs.lib.genAttrs
  [ "aarch64-linux" "x86_64-linux" ]
  (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt)
