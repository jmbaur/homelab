{ config, lib, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  services.nzbget.enable = true;
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  services.jackett = {
    enable = true;
    openFirewall = true;
  };
  services.lidarr = {
    enable = true;
    openFirewall = true;
  };
  services.radarr = {
    enable = true;
    openFirewall = true;
  };
  services.sonarr = {
    enable = true;
    openFirewall = true;
  };
  users.users.plex.extraGroups = [
    config.services.lidarr.group
    config.services.radarr.group
    config.services.sonarr.group
  ];
  users.users.lidarr.extraGroups = [ config.services.nzbget.group ];
  users.users.radarr.extraGroups = [ config.services.nzbget.group ];
  users.users.sonarr.extraGroups = [ config.services.nzbget.group ];
}
