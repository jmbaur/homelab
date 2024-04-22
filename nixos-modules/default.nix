inputs: {
  default =
    { ... }:
    {
      nixpkgs.overlays = with inputs; [ self.overlays.default ];
      imports = [
        ./basic-network.nix
        ./builder.nix
        ./clatd.nix
        ./common.nix
        ./desktop
        ./dev.nix
        ./hardware
        ./image
        ./normal-user
        ./server.nix
        ./wireless.nix
        inputs.ipwatch.nixosModules.default
        inputs.nixos-router.nixosModules.default
        inputs.sops-nix.nixosModules.sops
        inputs.tinyboot.nixosModules.default
        inputs.webauthn-tiny.nixosModules.default
      ];
    };
}
