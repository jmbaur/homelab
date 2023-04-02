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
      ./common.nix
      ./cross-compile.nix
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
      ./mesh-network
      ./remote-boot.nix
      ./remote-builder.nix
      ./server.nix
      ./wireless.nix
      ./zfs.nix
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
    ];
  };
}
