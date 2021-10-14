{ config, pkgs, ... }:

let
  nfs_port = 2049;
  unstable = import ../../lib/unstable.nix { };
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
    package = unstable.gitea; # To get mirroring benefits from 1.15.x;
    disableRegistration = true;
    httpPort = 3000;
    domain = "gitea.jmbaur.com";
    rootUrl = "https://gitea.jmbaur.com";
    cookieSecure = true;
    database = {
      type = "postgres";
      port = 5432;
    };
    dump = { enable = true; backupDir = "/data/gitea_dump"; };
  };

  services.postgresql = {
    enable = true;
    # Allow gitea and postgres user to the gitea database
    authentication = ''
      local gitea gitea ident
      local gitea postgres ident
    '';
  };

  services.postgresqlBackup = {
    enable = true;
    location = "/data/postgresql_backup";
  };

  systemd.timers."gitea-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = [ "weekly" ];
  };
  systemd.services."gitea-backup" = {
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "/run/keys/gitea-backup";
    };
    script = ''
      ${pkgs.awscli}/bin/aws s3 sync --storage-class GLACIER /data/gitea_dump s3://''${S3_BUCKET}/gitea_dump
      ${pkgs.awscli}/bin/aws s3 sync --storage-class GLACIER /data/postgresql_backup s3://''${S3_BUCKET}/postgresql_backup
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}


