inputs: with inputs; {
  artichoke.imports = [
    ../../nixosConfigurations/artichoke
    ipwatch.nixosModules.default
    self.nixosModules.default
    sops-nix.nixosModules.sops
  ];
  default = {
    nixpkgs.overlays = [
      self.overlays.default
      git-get.overlays.default
      gobar.overlays.default
      gosee.overlays.default
      pd-notify.overlays.default
      self.overlays.default
    ];
    imports = [
      ./common.nix
      ./deployee.nix
      ./deployer.nix
      ./dev.nix
      ./gui.nix
      ./he_tunnelbroker.nix
      ./home-manager
      ./installer.nix
      ./jared.nix
      ./laptop.nix
      ./remote_boot.nix
      ./remote_builder.nix
      ./wg_www_peer.nix
      ./zfs.nix
      home-manager.nixosModules.home-manager
    ];
    custom.common.enable = true;
  };
}
