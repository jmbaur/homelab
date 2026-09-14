inputs:
let
  inherit (inputs.nixpkgs.lib) filterAttrs;
in
{
  default = {
    nixpkgs.overlays = [ inputs.self.overlays.default ];
    imports = [
      # `services.hydra-dev`, `services.hydra-queue-runner-dev` and
      # `services.hydra-queue-builder-dev`. These replace nixpkgs'
      # `services.hydra`, whose queue runner is the old C++ one.
      inputs.hydra.nixosModules.web-app
      inputs.hydra.nixosModules.queue-runner
      inputs.hydra.nixosModules.builder
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
