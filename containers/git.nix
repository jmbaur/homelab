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
      if [ -z "''${1:-}" ]; then
        echo "no repo name provided, exiting"
        echo "usage: ${name} <my-repo-name>"
        exit 1
      fi

      repo_name=
      case "$1" in
      *.git$)
        repo_name="$1";;
      *)
        repo_name="$1.git";;
      esac

      if test -d "${config.services.gitDaemon.basePath}/''${repo_name}"; then
        echo "repo $repo_name already exists, exiting"
        exit 2
      fi

      git init --bare --initial-branch main "${config.services.gitDaemon.basePath}/''${repo_name}"
    '';
  };
  commands = pkgs.symlinkJoin {
    name = "git-shell-commands-environment";
    paths = [ create-repo ];
  };
in
{
  networking.firewall.allowedTCPPorts = [ 5678 ];
  system.activationScripts.git-shell-commands.text = ''
    ln -sf ${commands}/bin ${config.users.users.git.home}/git-shell-commands
    user=${config.services.gitDaemon.user}
    chown -R $user:$user ${config.users.users.git.home}/git-shell-commands
  '';
  users.users.git = {
    home = config.services.gitDaemon.basePath;
    createHome = true;
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../data/jmbaur-ssh-keys.nix);
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
