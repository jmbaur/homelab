{ config, lib, pkgs, ... }: {
  services.gitDaemon = {
    enable = true;
    exportAll = true;
  };
  services.nginx = {
    enable = true;
    gitweb.enable = true;
  };
  users.users.root.initialPassword = "helloworld";
}
