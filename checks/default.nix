inputs:

let
  inherit (inputs.nixpkgs.lib) filterAttrs mapAttrs;
in
mapAttrs (
  system: _:
  (mapAttrs
    # The tests import self.nixosModules.default, which sets the overlay at
    # self.overlays.default, so we don't reuse the pkgs from legacyPackages and
    # instead use pkgs from nixpkgs directly.
    (name: _: inputs.nixpkgs.legacyPackages.${system}.callPackage ./${name} { inherit inputs; })
    (filterAttrs (_: type: type == "directory") (builtins.readDir ./.))
  )
) inputs.self.legacyPackages
