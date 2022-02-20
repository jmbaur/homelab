{ config, lib, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  services.plex = {
    enable = true;
    openFirewall = true;
  };
}
