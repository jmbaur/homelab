{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    {
      custom.server = {
        enable = true;
        interfaces.broccoli-0.matchConfig.Path = "platform-xhci-hcd.0.auto-usb-0:1.1:1.0";
      };
      hardware.blackrock.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-1c20000.pcie-pci-0002:01:00.0-nvme-1";
    }
    {
      sops.secrets = {
        nix_signing_key = { };
        nix_signing_key2 = { };
        ssh_remote_build.owner = config.users.users.hydra-queue-runner.name;
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
      services.harmonia = {
        enable = true;
        signKeyPaths = [
          config.sops.secrets.nix_signing_key.path

          # TODO(jared): Remove after all hosts are validating with new key
          config.sops.secrets.nix_signing_key2.path
        ];

        # TODO(jared): switch to localhost after all hosts are using https://cache.jmbaur.com
        settings.bind = "[::]:5000";
      };

      # TODO(jared): Remove after all hosts are using https://cache.jmbaur.com
      custom.yggdrasil.all.allowedTCPPorts = [ 5000 ];

      services.nginx.virtualHosts."cache.jmbaur.com" = {
        onlySSL = true;
        locations."/" = {
          proxyPass = "http://[::1]:5000";
          extraConfig = ''
            proxy_set_header Accept-Encoding zstd;
          '';
        };
        sslCertificate = config.sops.secrets."cf-origin/cert".path;
        sslCertificateKey = config.sops.secrets."cf-origin/key".path;
      };
    }
    {
      nix.settings.netrc-file = config.sops.secrets.hydra_netrc.path;

      nix.settings.allowed-uris = [
        "https://"
        "github:"
      ];

      zramSwap.memoryPercent = 200;

      systemd.services.hydra-evaluator.environment.GC_DONT_GC = "1"; # https://github.com/NixOS/nix/issues/4178#issuecomment-738886808

      system.stateVersion = "25.05";

      services.hydra = {
        enable = true;
        logo = ./dr-doom.svg;
        hydraURL = "https://hydra.jmbaur.com";
        notificationSender = "hydra@localhost";
        useSubstitutes = true;
        extraConfig = ''
          allow_import_from_derivation = false
          binary_cache_public_uri = https://cache.jmbaur.com
          log_prefix = https://cache.jmbaur.com/
        '';
      };

      # TODO(jared): Remove after all hosts are using https://hydra.jmbaur.com
      custom.yggdrasil.all.allowedTCPPorts = [ 3000 ];

      services.nginx.virtualHosts."hydra.jmbaur.com" = {
        onlySSL = true;
        locations."/".proxyPass = "http://[::1]:3000";
        sslCertificate = config.sops.secrets."cf-origin/cert".path;
        sslCertificateKey = config.sops.secrets."cf-origin/key".path;
      };

      nix.distributedBuilds = true;
      nix.buildMachines = [
        {
          hostName = "localhost";
          protocol = null; # only works with "localhost" builder
          system = pkgs.stdenv.hostPlatform.system;
          supportedFeatures = config.nix.settings.system-features or [ ];
          maxJobs = 4;
        }
        {
          hostName = "potato.internal";
          protocol = "ssh"; # ssh-ng not supported by hydra (see https://github.com/NixOS/hydra/blob/18c0d762109549351ecf622cde34514351a72492/src/hydra-queue-runner/build-remote.cc#L375)
          sshUser = "builder";
          sshKey = config.sops.secrets.ssh_remote_build.path;
          system = "x86_64-linux";
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUFXS3ZpUXVXak90M0N3TDFKdURuVGM4M2tDbUdmZE52akxKMWVaa2I1MVEgcm9vdEBwb3RhdG8K";
          maxJobs = 4;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
        }
      ];
    }
  ];
}
