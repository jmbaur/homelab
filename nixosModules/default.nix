inputs: with inputs; {
  router = { ... }: {
    imports = [
      ./router
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };
  default = { ... }: {
    nixpkgs.overlays = [
      self.overlays.default
      gobar.overlays.default
      gosee.overlays.default
      pd-notify.overlays.default
      self.overlays.default
    ];
    imports = [
      ./chromebook.nix
      ./common.nix
      ./deployee.nix
      ./deployer.nix
      ./depthcharge
      ./dev.nix
      ./gui.nix
      ./hardware
      ./he_tunnelbroker.nix
      ./home-manager
      ./installer.nix
      ./jared.nix
      ./laptop.nix
      ./remote_boot.nix
      ./remote_builder.nix
      ./wg_www_peer.nix
      ./wireless.nix
      ./zfs.nix
      home-manager.nixosModules.home-manager
    ];
    custom.common.enable = true;
  };
}
