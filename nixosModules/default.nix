inputs: with inputs; {
  default = {
    nixpkgs.overlays = [
      nixos-configs.overlays.default
      self.overlays.default
    ];
    imports = [
      ./cn913x.nix
      ./cross_compiled.nix
      ./deployee.nix
      ./deployer.nix
      ./installer.nix
      ./jared.nix
      ./lx2k.nix
      ./remote_boot.nix
      ./remote_builder.nix
      ./thinkpad_x13s.nix
      ./wg_www_peer.nix
      ./zfs.nix
    ];
  };
}
