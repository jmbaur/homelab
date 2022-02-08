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
  networking.interfaces.mv-trusted = {
    ipv4.addresses = [{ address = "192.168.10.21"; prefixLength = 24; }];
  };
}
