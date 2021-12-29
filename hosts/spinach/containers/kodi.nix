{ config, lib, pkgs, ... }: {
  networking = {
    hostName = "kodi";
    interfaces.mv-eno2.useDHCP = true;
    firewall.allowedTCPPorts = [
      2049 # nfs
    ];
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /kodi *
  '';

  fileSystems."/kodi" = {
    device = "/mnt/kodi";
    options = [ "bind" ];
  };
}
