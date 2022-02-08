{ config, lib, pkgs, ... }: {
  services.gitDaemon = {
    enable = true;
  };
  services.nginx = {
    enable = true;
    gitweb.enable = true;
  };
  users.users.root.initialPassword = "helloworld";
}
