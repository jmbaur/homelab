{ config, lib, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  services.transmission.enable = true;
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  services.sonarr = {
    enable = true;
    openFirewall = true;
  };
  services.radarr = {
    enable = true;
    openFirewall = true;
  };
  services.lidarr = {
    enable = true;
    openFirewall = true;
  };
  services.jackett = {
    enable = true;
    openFirewall = true;
  };
  users.users.sonarr.extraGroups = [
    config.services.plex.group
    config.services.transmission.group
  ];
  users.users.radarr.extraGroups = [
    config.services.plex.group
    config.services.transmission.group
  ];
  users.users.lidarr.extraGroups = [
    config.services.plex.group
    config.services.transmission.group
  ];
}
