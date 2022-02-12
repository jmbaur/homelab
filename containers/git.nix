{ config, lib, pkgs, ... }:
let
  no-interactive-login = pkgs.writeShellApplication {
    name = "no-interactive-login";
    runtimeInputs = [ ];
    text = ''
      printf '%s\n' "Hi $USER! You've successfully authenticated, but I do not"
      printf '%s\n' "provide interactive shell access."
      exit 128
    '';
  };
  git-shell-commands = pkgs.symlinkJoin {
    name = "git-shell-commands";
    paths = [ no-interactive-login ];
  };
in
{
  networking.firewall.allowedTCPPorts = [ 5678 ];
  users.users = {
    git = {
      home = "${git-shell-commands}/bin";
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
