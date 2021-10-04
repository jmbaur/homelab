{ config, pkgs, ... }:

let
  nfs_port = 2049;
in
{
  imports = [ ./hardware-configuration.nix ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "kale";
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.eno2.useDHCP = true;
  networking.firewall.allowedTCPPorts = [ config.services.gitea.httpPort nfs_port ] ++ config.services.openssh.ports;
  # networking.firewall.allowedUDPPorts = [ ... ];

  # NFS
  fileSystems."/srv/nfs/kodi" = {
    device = "/data/kodi";
    options = [ "bind" ];
  };
  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/nfs       rhubarb.lan(rw,sync,crossmnt,fsid=0)
      /srv/nfs/kodi  rhubarb.lan(rw,all_squash,insecure)
    '';
  };

  # SSH
  services.openssh.enable = true;
  services.openssh.ports = [ 22 2082 ];
  users.extraUsers.root.openssh.authorizedKeys.keys =
    [ "${builtins.readFile ../../lib/publicSSHKey.txt}" ];

  # Syncthing
  services.syncthing = {
    enable = true;
    configDir = "/data/syncthing/.config/syncthing";
    dataDir = "/data/syncthing";
    openDefaultPorts = true;
    declarative = {
      overrideFolders = true;
      overrideDevices = true;
      devices = {
        beetroot.id =
          "ECKHOPT-LWUOIFJ-ZRR2YA5-TQQQNOZ-LNSSNIQ-NHGC4EL-VLZCZQQ-G6WLOQA";
        okra.id =
          "TF2ZKRU-G2EJKBJ-JLSGABK-UHQMZGB-SFCO7X3-A4EB674-3LMSNAL-3QPCVQE";
      };
      folders = {
        Desktop = {
          devices = [ "beetroot" "okra" ];
          path = "/data/syncthing/Desktop";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
        Documents = {
          devices = [ "beetroot" "okra" ];
          path = "/data/syncthing/Documents";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
        Downloads = {
          devices = [ "beetroot" "okra" ];
          path = "/data/syncthing/Downloads";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
        Pictures = {
          devices = [ "beetroot" "okra" ];
          path = "/data/syncthing/Pictures";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
        Music = {
          devices = [ "beetroot" "okra" ];
          path = "/data/syncthing/Music";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
        Videos = {
          devices = [ "beetroot" "okra" ];
          path = "/data/syncthing/Videos";
          versioning = {
            type = "simple";
            params = { keep = "10"; };
          };
        };
      };
    };
  };

  users.users.gitea = {
    group = "gitea";
    extraGroups = [ "keys" ];
    isSystemUser = true;
  };

  services.gitea = {
    enable = true;
    disableRegistration = true;
    httpPort = 3000;
    database = {
      type = "postgres";
      port = 5432;
      passwordFile = "/run/keys/gitea_db_pass";
    };
    dump = {
      enable = true;
      backupDir = "/data/gitea_dump";
    };
  };

  services.postgresql = {
    enable = true;
    authentication = ''
      local gitea all ident map=gitea-users
    '';
    identMap = ''
      gitea-users gitea gitea
    '';
  };

  services.postgresqlBackup = {
    enable = true;
    location = "/data/postgresql_backup";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
