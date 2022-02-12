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
  create-repo = pkgs.writeShellApplication rec {
    name = "create-repo";
    runtimeInputs = [ pkgs.git ];
    text = ''
      if [ -z "$1" ]; then
        echo "no repo name provided, exiting"
        echo "usage: ${name} <my-repo-name>"
        exit 1
      fi
      git init --bare --initial-branch main "${config.services.gitDaemon.basePath}/$1"
    '';
  };
  commands = pkgs.symlinkJoin {
    name = "git-shell-commands-environment";
    paths = [ create-repo ];
  };
  git-shell-commands = pkgs.runCommandNoCC "git-shell-commands" { } ''
    mkdir -p $out
    ln -s ${commands}/bin $out/git-shell-commands
  '';
in
{
  networking.firewall.allowedTCPPorts = [ 5678 ];
  users.users = {
    git = {
      home = git-shell-commands;
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
