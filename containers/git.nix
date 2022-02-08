{ config, lib, pkgs, ... }: {
  services.gitDaemon = {
    enable = true;
    exportAll = true;
  };
  services.nginx = {
    enable = true;
    gitweb.enable = true;
  };
  users.mutableUsers = false;
  users.users.jared.isNormalUser = true;
  users.users.jared.password = "helloworld";
  networking.useDHCP = true;
  # networking.interfaces.mv-trusted = { };
}
