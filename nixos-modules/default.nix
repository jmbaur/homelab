inputs: {
  default = {
    nixpkgs.overlays = with inputs; [ self.overlays.default ];
    imports = [
      ./basic-network
      ./builder.nix
      ./common.nix
      ./desktop
      ./dev.nix
      ./hardware
      ./image
      ./kodi
      ./nested-builder.nix
      ./dynamic-dns
      ./normal-user
      ./server.nix
      ./wg-network.nix
      inputs.ipwatch.nixosModules.default
      inputs.nixos-router.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.tinyboot.nixosModules.default
      inputs.webauthn-tiny.nixosModules.default
    ];
  };
}
