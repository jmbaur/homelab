inputs: {
  default = { ... }: {
    nixpkgs.overlays = with inputs; [ self.overlays.default ];
    imports = [
      ./basic-network.nix
      ./btrfs.nix
      ./builder.nix
      ./common.nix
      ./deployee.nix
      ./depthcharge
      ./dev.nix
      ./gui
      ./hardware
      ./image
      ./installer.nix
      ./jared
      ./laptop.nix
      ./mesh-network
      ./remote-boot.nix
      ./remote-builder.nix
      ./server.nix
      ./wireless.nix
      ./zfs.nix
      inputs.ipwatch.nixosModules.default
      inputs.nixos-router.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.tinyboot.nixosModules.default
      inputs.webauthn-tiny.nixosModules.default
    ];
  };
}
