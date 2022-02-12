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
      name=''${1:-}
      description=''${2:-}

      if [ -z "$name" ]; then
        echo "no repo name provided, exiting"
        echo "usage: ${name} \"<my-repo-name>\" \"<my-repo-description>\""
        exit 1
      fi

      final_name=
      case "$name" in
      *.git$)
        final_name="''${name}";;
      *)
        final_name="''${name}.git";;
      esac

      full_path="${config.services.gitDaemon.basePath}/''${final_name}"

      if [ -d "$full_path" ]; then
        echo "repo $final_name already exists, exiting"
        exit 2
      fi

      git init --bare --initial-branch main "$full_path"

      if [ -n "$description" ]; then
        echo "$description" > "''${full_path}/description"
      fi
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
    ln -sfT ${commands}/bin ${config.users.users.git.home}/git-shell-commands
    chown -R ${config.services.gitDaemon.user}:${config.users.extraGroups.users.name} ${config.users.users.git.home}/git-shell-commands
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
