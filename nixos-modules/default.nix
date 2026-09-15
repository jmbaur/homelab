inputs:
let
  inherit (inputs.nixpkgs.lib) filterAttrs;
in
{
  default = {
    nixpkgs.overlays = [ inputs.self.overlays.default ];
    imports = [
      inputs.hydra.nixosModules.builder
      inputs.hydra.nixosModules.queue-runner
      inputs.hydra.nixosModules.web-app
      inputs.jetpack-nixos.nixosModules.default
      inputs.nixos-router.nixosModules.default
      inputs.quartus-nix.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.tinyboot.nixosModules.default
      inputs.webauthn-tiny.nixosModules.default
    ]
    ++ map (directory: ./${directory}) (
      builtins.attrNames (filterAttrs (_: entryType: entryType == "directory") (builtins.readDir ./.))
    );
  };
}
