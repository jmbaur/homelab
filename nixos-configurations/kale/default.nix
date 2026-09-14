{
  config,
  lib,
  ...
}:
let
  inherit (builtins) listToAttrs genList;
  inherit (lib)
    mkForce
    mkMerge
    ;
in
{
  config = mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      hardware.cpu.amd.updateMicrocode = true;
      hardware.enableRedistributableFirmware = true;

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "uas"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      boot.kernelParams = [ "console=ttyS0,115200" ];

      nixpkgs.config.allowUnfree = true;
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        nvidiaSettings = false;
        open = false;
      };

      boot.kernel.sysfs.devices.system.cpu = listToAttrs (
        genList (x: {
          name = "cpu${toString x}";
          value.cpufreq.scaling_governor = "powersave";
        }) 24
      );
    }
    {
      custom.server = {
        enable = true;
        interfaces.kale-0.matchConfig.Path = "pci-0000:01:00.0";
      };
      custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:41:00.0-nvme-1";

      fileSystems."/var" = {
        fsType = "btrfs";
        device = "/dev/disk/by-partlabel/big";
        options = [
          "compress=zstd"
          "noatime"
          "discard=async"
        ];
      };

      fileSystems."/mnt/media" = {
        fsType = "btrfs";
        device = "/dev/disk/by-partlabel/media";
        options = [
          "compress=zstd"
          "defaults"
          "noatime"
          "subvol=/data"
        ];
      };

      services.fwupd.enable = true;

      sops.secrets = {
        nix_signing_key = { };
        hydra_netrc.owner = config.users.users.hydra.name;
        "cf-origin/cert".owner = config.services.nginx.user;
        "cf-origin/key".owner = config.services.nginx.user;
      };

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
      # Ensure our build machine doesn't attempt to use itself as a substituter
      nix.settings.substituters = mkForce [ "https://cache.nixos.org" ];
      nix.settings.extra-substituters = mkForce [ ];

      nix.settings.netrc-file = config.sops.secrets.hydra_netrc.path;

      nix.settings.allowed-uris = [
        "https://"
        "github:"
      ];

      zramSwap.memoryPercent = 200;

      system.stateVersion = "26.11";

      services.hydra-dev = {
        enable = true;
        logo = ./dr-doom.svg;
        hydraURL = "https://hydra.jmbaur.com";
        notificationSender = "hydra@localhost";
        useSubstitutes = true;
        extraConfig = ''
          allow_import_from_derivation = false
          evaluator_workers = 8
          evaluator_max_memory_size = 8192
          binary_cache_public_uri = https://cache.jmbaur.com
          log_prefix = https://cache.jmbaur.com/
          queue_runner_endpoint = http://[::1]:${toString config.services.hydra-queue-runner-dev.rest.port}
        '';
      };

      services.hydra-queue-runner-dev = {
        enable = true;

        grpc.address = "[::]";
        grpc.port = 50051;
        rest.port = 8080;

        settings = {
          remoteStoreAddr = [ "http://[::1]:8501/upload" ];

          useSubstitutes = true;

          maxOutputSize = 4 * 1024 * 1024 * 1024; # 4 GiB
        };
      };

      services.hydra-queue-builder-dev = {
        enable = true;
        queueRunnerAddr = "http://[::1]:${toString config.services.hydra-queue-runner-dev.grpc.port}";
        settings.maxJobs = 24;
      };

      custom.yggdrasil.peers.broccoli.allowedTCPPorts = [
        config.services.hydra-queue-runner-dev.grpc.port
      ];

      services.nginx.virtualHosts."cache.jmbaur.com" = {
        onlySSL = true;
        locations."/".proxyPass = "http://[::1]:8501";
        locations."/upload" = {
          proxyPass = "http://[::1]:8501";
          extraConfig = ''
            allow 127.0.0.1;
            allow ::1;
            deny all;
          '';
        };
        sslCertificate = config.sops.secrets."cf-origin/cert".path;
        sslCertificateKey = config.sops.secrets."cf-origin/key".path;
      };

      services.ncps = {
        enable = true;
        cache = {
          secretKeyPath = config.sops.secrets.nix_signing_key.path;
          hostName = "cache.jmbaur.com-1";
          upstream.urls = [ "https://cache.nixos.org" ];
          upstream.publicKeys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
          maxSize = "512G";
          lru.schedule = "0 2 * * *";
          allowPutVerb = true;
        };
      };

      networking.nftables.flushRuleset = !config.nix.firewall.enable;

      nix.firewall = {
        enable = true;
        allowPrivateNetworks = false;
        allowedTCPPorts = [
          22 # SSH (for git+ssh:// URLs)
          80 # HTTP
          443 # HTTPS
        ];
        allowedUDPPorts = [
          53 # DNS
          443 # QUIC/HTTP3
        ];
      };

      services.nginx.virtualHosts."hydra.jmbaur.com" = {
        onlySSL = true;
        locations."/".proxyPass = "http://[::1]:3000";
        sslCertificate = config.sops.secrets."cf-origin/cert".path;
        sslCertificateKey = config.sops.secrets."cf-origin/key".path;
      };
    }
    {
      fileSystems."/var/lib/jellyfin" = {
        fsType = "none";
        options = [ "bind" ];
        device = "/mnt/media/jellyfin";
      };

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
      fileSystems."/var/lib/navidrome" = {
        fsType = "none";
        options = [ "bind" ];
        device = "/mnt/media/navidrome";
      };

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
  ];
}
