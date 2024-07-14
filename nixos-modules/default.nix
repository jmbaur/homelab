inputs: {
  default =
    { ... }:
    {
      nixpkgs.overlays = with inputs; [
        inputs.nixos-apple-silicon.overlays.default
        inputs.u-boot-nix.overlays.default
        self.overlays.default
      ];
      imports = [
        ./basic-network
        ./builder.nix
        ./common.nix
        ./desktop
        ./dev.nix
        ./hardware
        ./image
        ./normal-user
        ./server.nix
        ./tmux-server.nix
        ./wg-network.nix
        inputs.ipwatch.nixosModules.default
        inputs.nixos-router.nixosModules.default
        inputs.sops-nix.nixosModules.sops
        inputs.tinyboot.nixosModules.default
        inputs.webauthn-tiny.nixosModules.default
      ];
    };
}
