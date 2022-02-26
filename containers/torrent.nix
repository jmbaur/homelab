{ config, lib, pkgs, ... }: {
  services.rtorrent = {
    enable = true;
  };
  services.sonarr = {
    enable = true;
  };
  services.radarr = {
    enable = true;
  };
  services.lidarr = {
    enable = true;
  };
  services.jackett = {
    enable = true;
  };
}
