{ config, lib, pkgs, ... }: {
  users.users.sonarr.extraGroups = [ config.services.transmission.group ];
  users.users.radarr.extraGroups = [ config.services.transmission.group ];
  users.users.lidarr.extraGroups = [ config.services.transmission.group ];
  services.transmission = {
    enable = true;
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
}
