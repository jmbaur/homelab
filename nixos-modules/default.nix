inputs: {
  default = {
    nixpkgs.overlays = with inputs; [
      gobar.overlays.default
      gosee.overlays.default
      pd-notify.overlays.default
      self.overlays.default
      self.overlays.default
    ];
    imports = [
      ./basic-network.nix
      ./btrfs.nix
      ./chromebook.nix
      ./common.nix
      ./deployee.nix
      ./deployer.nix
      ./depthcharge
      ./dev.nix
      ./gui
      ./hardware
      ./home-manager
      ./installer.nix
      ./jared.nix
      ./laptop.nix
      ./remote-boot.nix
      ./remote-builder.nix
      ./server.nix
      ./wg-www-peer.nix
      ./wireless.nix
      ./zfs.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
