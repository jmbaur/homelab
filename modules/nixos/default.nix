inputs: with inputs; {
  artichoke.imports = [
    ../../nixosConfigurations/artichoke
    ipwatch.nixosModules.default
    nixos-configs.nixosModules.default
    self.nixosModules.default
    sops-nix.nixosModules.sops
  ];
  default = {
    nixpkgs.overlays = [ nixos-configs.overlays.default self.overlays.default ];
    imports = [
      ./cross_compiled.nix
      ./deployee.nix
      ./deployer.nix
      ./he_tunnelbroker.nix
      ./installer.nix
      ./inventory.nix
      ./jared.nix
      ./remote_boot.nix
      ./remote_builder.nix
      ./wg_www_peer.nix
      ./zfs.nix
    ];
  };
}
