{ config, lib, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  services.nzbget = {
    enable = true;
    settings = {
      "Server1.Port" = 563;
      "Server1.Host" = "news.eweka.nl";
      "Server1.Username" = "$(cat /run/secrets/eweka/username)";
      "Server1.Password" = "$(cat /run/secrets/eweka/password)";
      "Server1.Encryption" = true;
    };
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
