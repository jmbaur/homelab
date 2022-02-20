{ config, lib, pkgs, ... }: {
  services.plex = {
    enable = true;
    openFirewall = true;
  };
}
