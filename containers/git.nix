{ config, lib, pkgs, ... }:
let
  cgitrc = pkgs.writeText "cgitrc" ''
    about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
    source-filter=${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    snapshots=tar.gz zip
    cache-size=1000
    remove-suffix=1
    scan-path=${config.services.gitDaemon.basePath}
  '';
in
{
  networking.firewall.allowedTCPPorts = [ 80 ];
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
    user = services.gitDaemon.user;
    group = services.gitDaemon.group;
  };
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };
}
