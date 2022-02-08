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
  users.users.root.password = "helloworld";
  # networking.interfaces.mv-trusted = { };
}
