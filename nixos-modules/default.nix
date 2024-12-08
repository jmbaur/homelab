inputs:
let
  inherit (inputs.nixpkgs.lib) filterAttrs;
in
{
  default = {
    nixpkgs.overlays = with inputs; [ self.overlays.default ];
    imports =
      [
        inputs.ipwatch.nixosModules.default
        inputs.nixos-router.nixosModules.default
        inputs.nixos-wsl.nixosModules.default
        inputs.sops-nix.nixosModules.sops
        inputs.tinyboot.nixosModules.default
        inputs.webauthn-tiny.nixosModules.default
      ]
      ++ map (directory: ./${directory}) (
        builtins.attrNames (filterAttrs (_: entryType: entryType == "directory") (builtins.readDir ./.))
      );
  };
}
