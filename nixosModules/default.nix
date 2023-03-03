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
      ./basic_network.nix
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
      ./remote_boot.nix
      ./remote_builder.nix
      ./server.nix
      ./wg_www_peer.nix
      ./wireless.nix
      ./zfs.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
