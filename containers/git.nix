{ config, lib, pkgs, ... }: {
  networking.firewall.allowedTCPPorts = [ 5678 ];
  users.users = {
    git = {
      home = config.services.gitDaemon.basePath;
      createHome = true;
      shell = "${pkgs.git}/bin/git-shell";
      openssh.authorizedKeys.keyFiles = lib.singleton (import ../data/jmbaur-ssh-keys.nix);
    };
  };
  services.gitDaemon = {
    enable = true;
    exportAll = true;
    basePath = "/srv/git";
  };
  services.fcgiwrap = {
    enable = true;
    socketType = "tcp";
    socketAddress = "0.0.0.0:5678";
    user = config.services.gitDaemon.user;
    group = config.services.gitDaemon.group;
  };
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };
}
