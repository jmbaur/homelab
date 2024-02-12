inputs: {
  default = { ... }: {
    nixpkgs.overlays = with inputs; [ self.overlays.default ];
    imports = [
      ./basic-network.nix
      ./btrfs.nix
      ./builder.nix
      ./common.nix
      ./dev.nix
      ./gui
      ./hardware
      ./image
      ./installer
      ./jared
      ./laptop.nix
      ./mesh-network
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
