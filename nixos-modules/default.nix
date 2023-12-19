inputs: {
  default = {
    _module.args = { inherit inputs; };
    nixpkgs.overlays = with inputs; [ self.overlays.default ];
    imports = [
      ./basic-network.nix
      ./btrfs.nix
      ./builder.nix
      ./common.nix
      ./cross-compile.nix
      ./deployee.nix
      ./depthcharge
      ./dev.nix
      ./gui
      ./hardware
      ./installer.nix
      ./jared
      ./laptop.nix
      ./mesh-network
      ./remote-boot.nix
      ./remote-builder.nix
      ./server.nix
      ./tinyboot-installer.nix
      ./wireless.nix
      ./zfs.nix
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      inputs.tinyboot.nixosModules.default
    ];
  };
}
