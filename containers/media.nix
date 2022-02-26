{ config, lib, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  services.sabnzbd = {
    enable = true;
    configFile = "/run/secrets/sabnzbd.ini";
  };
  systemd.services.sabnzbd = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
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
  users.users.lidarr.extraGroups = [ config.services.sabnzbd.group ];
  users.users.radarr.extraGroups = [ config.services.sabnzbd.group ];
  users.users.sonarr.extraGroups = [ config.services.sabnzbd.group ];
}
