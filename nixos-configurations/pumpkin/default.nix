{ config, lib, ... }:

{
  config = lib.mkMerge [
    {
      hardware.macchiatobin.enable = true;

      custom.recovery.targetDisk = "/dev/disk/by-path/platform-f06e0000.mmc";
      custom.server = {
        enable = true;
        interfaces.pumpkin-0.matchConfig.Path = "platform-f2000000.ethernet";
      };

      fileSystems."/var" = {
        fsType = "btrfs";
        device = "/dev/disk/by-partlabel/data";
        options = [
          "compress=zstd"
          "defaults"
          "noatime"
          "subvol=/data"
        ];
      };

      # This machine has many interfaces, and we currently only care that one
      # has an "online" status.
      systemd.network.wait-online.anyInterface = true;
    }
    {
      sops.secrets."cf-origin/cert".owner = config.services.nginx.user;
      sops.secrets."cf-origin/key".owner = config.services.nginx.user;
      sops.secrets."garage-htpasswd".owner = config.services.nginx.user;

      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;
        virtualHosts."${config.networking.hostName}.jmbaur.com" = {
          onlySSL = true;
          locations."/".return = 404;
          sslCertificate = config.sops.secrets."cf-origin/cert".path;
          sslCertificateKey = config.sops.secrets."cf-origin/key".path;
        };
      };

      networking.firewall.allowedTCPPorts = [ 443 ];
    }
    {
      custom.yggdrasil.peers.onion.allowedTCPPorts = [ config.services.navidrome.settings.Port ];

      services.navidrome = {
        enable = true;
        settings = {
          Address = "[::1]";
          Port = 4533;
          DefaultTheme = "Auto";
        };
      };

      services.nginx.virtualHosts."music.jmbaur.com" = {
        onlySSL = true;
        locations."/".proxyPass = "http://[::1]:${toString config.services.navidrome.settings.Port}";
        sslCertificate = config.sops.secrets."cf-origin/cert".path;
        sslCertificateKey = config.sops.secrets."cf-origin/key".path;
      };
    }
    {
      custom.yggdrasil.peers.onion.allowedTCPPorts = [ 8096 ];

      services.jellyfin.enable = true;

      services.nginx.virtualHosts."jellyfin.jmbaur.com" = {
        onlySSL = true;
        locations."/".proxyPass = "http://[::1]:8096";
        sslCertificate = config.sops.secrets."cf-origin/cert".path;
        sslCertificateKey = config.sops.secrets."cf-origin/key".path;
      };
    }
    {
      services.nginx.virtualHosts."garage.jmbaur.com" = {
        onlySSL = true;
        basicAuthFile = config.sops.secrets."garage-htpasswd".path;
        locations."/".proxyPass = "http://rhubarb.internal:8080";
        locations."/cam".proxyPass = "http://rhubarb.internal:8889";
        sslCertificate = config.sops.secrets."cf-origin/cert".path;
        sslCertificateKey = config.sops.secrets."cf-origin/key".path;
      };
    }
  ];
}
