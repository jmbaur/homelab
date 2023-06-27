inputs: {
  default = {
    _module.args = { inherit inputs; };
    nixpkgs.overlays = with inputs; [
      gobar.overlays.default
      gosee.overlays.default
      nixpkgs-wayland.overlays.default
      pd-notify.overlays.default
      self.overlays.default
    ];
    imports = [
      ./basic-network.nix
      ./btrfs.nix
      ./builder.nix
      ./common.nix
      ./cross-compile.nix
      ./deployee.nix
      ./deployer.nix
      ./depthcharge
      ./dev.nix
      ./file.nix
      ./gui
      ./hardware
      ./home-manager
      ./installer.nix
      ./jared
      ./laptop.nix
      ./mesh-network
      ./remote-boot.nix
      ./remote-builder.nix
      ./server.nix
      ./wireless.nix
      ./zfs.nix
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.tinyboot.nixosModules.default
    ];
  };
}
