{ config, lib, pkgs, ... }: {
  services.gitDaemon = {
    enable = true;
    exportAll = true;
  };
  services.nginx = {
    enable = true;
    gitweb.enable = true;
  };
  networking.interfaces.mv-trusted.useDHCP = true;
}
