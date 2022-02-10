{ config, lib, pkgs, ... }: {
  networking.firewall.allowedTCPPorts = [ 2049 ];
  fileSystems."/srv/kodi" = {
    device = "/kodi";
    options = lib.singleton "bind";
  };
  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/kodi *
    '';
  };
}
