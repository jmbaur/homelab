{ lib, config, pkgs, ... }:
let cfg = config.custom.users.jared; in
with lib;
{
  options.custom.users.jared = {
    enable = mkEnableOption "jared";
    passwordFile = mkOption {
      type = types.nullOr types.path;
    };
  };
  config = mkIf cfg.enable {
    users.users.jared = {
      isNormalUser = true;
      description = "Jared Baur";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
      extraGroups = [ "dialout" "wheel" ]
        ++ (optional config.networking.networkmanager.enable "networkmanager")
        ++ (optional config.programs.wireshark.enable "wireshark")
        ++ (optional config.programs.adb.enable "adbusers")
        ++ (optional config.virtualisation.docker.enable "docker")
      ;
    } // mkIf (cfg.passwordFile != null) {
      inherit (cfg) passwordFile;
    };

    home-manager.users.jared = { config, pkgs, ... }: {
      programs.git = {
        userEmail = "jaredbaur@fastmail.com";
        userName = "Jared Baur";
        extraConfig = {
          commit.gpgSign = true;
          gpg.format = "ssh";
          gpg.ssh.defaultKeyCommand = "ssh-add -L";
          gpg.ssh.allowedSignersFile = toString (pkgs.writeText "allowedSignersFile" ''
            ${config.programs.git.userEmail} sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
            ${config.programs.git.userEmail} sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
          '');
          user.signingKey = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=";
        };
      };
      programs.gpg.publicKeys = [{ trust = 5; source = pkgs.jmbaur-keybase-pgp-keys; }];
      programs.ssh = {
        enable = true;
        matchBlocks = {
          "*.mgmt.home.arpa".forwardAgent = true;
          work = {
            user = "jbaur";
            hostname = "dev.work.home.arpa";
            dynamicForwards = [{ port = 9050; }];
            localForwards = [
              { bind.port = 1025; host.address = "localhost"; host.port = 1025; }
              { bind.port = 8000; host.address = "localhost"; host.port = 8000; }
            ];
          };
        };
      };
    };
  };
}
