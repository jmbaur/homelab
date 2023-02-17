{ lib, config, pkgs, ... }:
let cfg = config.custom.users.jared; in
with lib;
{
  options.custom.users.jared = {
    enable = mkEnableOption "jared";
    passwordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
    };
  };
  config = mkIf cfg.enable {
    programs.fish.enable = true;
    users.users.jared = {
      inherit (cfg) passwordFile;
      isNormalUser = true;
      description = "Jared Baur";
      shell = pkgs.fish;
      openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-github-ssh-keys ];
      extraGroups = [ "dialout" "wheel" ]
        ++ (lib.optional config.networking.networkmanager.enable "networkmanager")
        ++ (lib.optional config.programs.adb.enable "adbusers")
        ++ (lib.optional config.programs.flashrom.enable "flashrom")
        ++ (lib.optional config.programs.wireshark.enable "wireshark")
        ++ (lib.optional config.virtualisation.docker.enable "docker")
      ;
    };

    home-manager.users.jared = { systemConfig, config, pkgs, ... }: {
      programs.git = {
        userEmail = "jaredbaur@fastmail.com";
        userName = systemConfig.users.users.jared.description;
        extraConfig = {
          commit.gpgSign = true;
          gpg.format = "ssh";
          gpg.ssh.defaultKeyCommand = "ssh-add -L";
          gpg.ssh.allowedSignersFile = toString (pkgs.writeText "allowedSignersFile" ''
            ${config.programs.git.userEmail} sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
            ${config.programs.git.userEmail} sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
          '');
          url."git@github.com:".pushInsteadOf = "https://github.com/";
          user.signingKey = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=";
        };
      };
      programs.gpg.publicKeys = [
        {
          trust = 5;
          source = pkgs.fetchurl {
            url = "https://keybase.io/jaredbaur/pgp_keys.asc";
            sha256 = "0rw02akfvdrpdrznhaxsy8105ng5r8xb5mlmjwh9msf4brnbwrj7";
          };
        }
      ];
      programs.ssh = {
        enable = true;
        matchBlocks = {
          "*.home.arpa".forwardAgent = true;
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
