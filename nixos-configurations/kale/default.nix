{
  config,
  lib,
  pkgs,
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
        nix_signing_key.owner = config.users.users.hydra-queue-runner.name;
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

        awsCredentialsFile = "/var/lib/hydra/queue-runner/aws-credentials";

        settings = {
          remoteStoreAddr = [
            "s3://cache.jmbaur.com?endpoint=http://[::1]:3900&region=garage&scheme=http&compression=zstd&log-compression=br&secret-key=${config.sops.secrets.nix_signing_key.path}"
          ];

          useSubstitutes = true;

          maxOutputSize = 4 * 1024 * 1024 * 1024; # 4 GiB
        };
      };

      systemd.services.hydra-queue-runner-dev = {
        requires = [ "garage-bootstrap.service" ];
        after = [ "garage-bootstrap.service" ];
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
        root = pkgs.writeTextDir "index.html" (
          let
            publicKey =
              lib.findFirst (lib.hasPrefix "cache.jmbaur.com-1:") (throw "missing cache.jmbaur.com public key")
                config.nix.settings.trusted-public-keys;
          in
          ''
            <!doctype html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <title>cache.jmbaur.com</title>
              <style>
                body { font-family: system-ui, sans-serif; max-width: 48rem; margin: 2rem auto; padding: 0 1rem; line-height: 1.5; }
                pre { background: #8881; padding: 1rem; overflow-x: auto; }
              </style>
            </head>
            <body>
              <h1>cache.jmbaur.com</h1>
              <h2>nix.conf</h2>
              <pre>extra-substituters = https://cache.jmbaur.com
            extra-trusted-public-keys = ${publicKey}</pre>
              <h2>NixOS</h2>
              <pre>nix.settings = {
              extra-substituters = [ "https://cache.jmbaur.com" ];
              extra-trusted-public-keys = [ "${publicKey}" ];
            };</pre>
            </body>
            </html>
          ''
        );
        locations."= /".tryFiles = "/index.html =404";
        locations."= /index.html" = { };
        locations."/".proxyPass = "http://[::1]:3902";
        # hydra's S3 uploader doesn't write this
        locations."= /nix-cache-info" = {
          alias = pkgs.writeText "nix-cache-info" ''
            StoreDir: /nix/store
            WantMassQuery: 1
            Priority: 10
          '';
          extraConfig = "default_type text/x-nix-cache-info;";
        };
        sslCertificate = config.sops.secrets."cf-origin/cert".path;
        sslCertificateKey = config.sops.secrets."cf-origin/key".path;
      };

      services.garage = {
        enable = true;
        package = pkgs.garage_2;
        environmentFile = "/var/lib/garage-rpc-secret/env";
        settings = {
          replication_factor = 1;
          # NARs are already compressed
          compression_level = "none";
          rpc_bind_addr = "[::1]:3901";
          rpc_public_addr = "[::1]:3901";
          s3_api = {
            s3_region = "garage";
            api_bind_addr = "[::1]:3900";
          };
          s3_web = {
            bind_addr = "[::1]:3902";
            root_domain = ".web.garage";
          };
        };
      };

      # Single node, so the RPC secret never needs to leave kale.
      systemd.services.garage-rpc-secret = {
        wantedBy = [ "garage.service" ];
        before = [ "garage.service" ];
        unitConfig.ConditionPathExists = "!/var/lib/garage-rpc-secret/env";
        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "garage-rpc-secret";
          StateDirectoryMode = "0700";
          UMask = "0077";
        };
        script = ''
          echo "GARAGE_RPC_SECRET=$(od -An -tx1 -N32 /dev/urandom | tr -d ' \n')" > "$STATE_DIRECTORY/env"
        '';
      };

      systemd.services.garage-bootstrap = {
        requires = [ "garage.service" ];
        after = [ "garage.service" ];
        path = [
          config.services.garage.package
          pkgs.curl
          pkgs.gawk
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          EnvironmentFile = config.services.garage.environmentFile;
        };
        script = ''
          creds=/var/lib/hydra/queue-runner/aws-credentials

          for _ in $(seq 60); do
            garage status >/dev/null 2>&1 && break
            sleep 1
          done
          garage status >/dev/null

          if ! garage layout show | grep -q 'Current cluster layout version: [1-9]'; then
            garage layout assign -z kale -c 1T "$(garage node id -q | cut -d@ -f1)"
            garage layout apply --version 1
          fi

          garage bucket info cache.jmbaur.com >/dev/null 2>&1 || garage bucket create cache.jmbaur.com
          garage bucket website --allow cache.jmbaur.com
          garage key info hydra-queue-runner >/dev/null 2>&1 || garage key create hydra-queue-runner
          garage bucket allow --read --write --key hydra-queue-runner cache.jmbaur.com

          info=$(garage key info --show-secret hydra-queue-runner)
          id=$(awk '/Key ID:/ {print $3}' <<<"$info")
          secret=$(awk '/Secret key:/ {print $3}' <<<"$info")

          install -d -m 0700 -o hydra-queue-runner -g hydra "$(dirname "$creds")"
          umask 077
          printf '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' "$id" "$secret" > "$creds.tmp"
          chown hydra-queue-runner:hydra "$creds.tmp"
          mv "$creds.tmp" "$creds"

          # Lifecycle rules are S3-API only. Keep this above hydra's 60 day
          # presence-cache TTL so it never skips re-uploading an expired path.
          curl --fail-with-body -sS -X PUT \
            --aws-sigv4 "aws:amz:garage:s3" --user "$id:$secret" \
            --data-binary '<LifecycleConfiguration><Rule><ID>expire</ID><Status>Enabled</Status><Filter></Filter><Expiration><Days>90</Days></Expiration></Rule></LifecycleConfiguration>' \
            'http://[::1]:3900/cache.jmbaur.com?lifecycle'
        '';
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
