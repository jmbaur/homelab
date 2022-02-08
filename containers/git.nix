{ config, lib, pkgs, ... }: {
  services.gitDaemon = {
    enable = true;
    exportAll = true;
  };
  services.gitweb.gitwebTheme = true;
  services.nginx = {
    enable = true;
    gitweb.enable = true;
  };
  networking.firewall.allowedTCPPorts = [ 80 ];
  networking.interfaces.mv-trusted.useDHCP = true;
}
