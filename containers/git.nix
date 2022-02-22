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

      full_path="''${HOME}/''${final_name}"

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
  system.userActivationScripts.git-shell-commands.text = ''
    ln -sfT ${commands}/bin $HOME/git-shell-commands
  '';
  users.users.jared = {
    isNormalUser = true;
    shell = "${pkgs.git}/bin/git-shell";
    description = "Jared Baur";
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../data/jmbaur-ssh-keys.nix);
  };
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };
  services.fail2ban.enable = true;
}
