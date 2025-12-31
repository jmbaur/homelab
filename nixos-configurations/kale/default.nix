{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) listToAttrs genList;
  inherit (lib) mkMerge;
in
{
  config = mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      nixpkgs.buildPlatform = config.nixpkgs.hostPlatform;

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

      services.fwupd.enable = true;

      sops.secrets = {
        nix_signing_key.owner = config.users.users.hydra-queue-runner.name;
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
      nix.settings.netrc-file = config.sops.secrets.hydra_netrc.path;

      nix.settings.allowed-uris = [
        "https://"
        "github:"
      ];

      zramSwap.memoryPercent = 200;

      system.stateVersion = "26.05";

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
          store_uri = file:///var/lib/binary-cache?compression=zstd&parallel-compression=true&ls-compression=br&log-compression=br&write-nar-listing=true&secret-key=${config.sops.secrets.nix_signing_key.path}
        '';
      };

      services.nginx.virtualHosts."cache.jmbaur.com" = {
        onlySSL = true;
        locations."/".root = "/var/lib/binary-cache";
        sslCertificate = config.sops.secrets."cf-origin/cert".path;
        sslCertificateKey = config.sops.secrets."cf-origin/key".path;
      };

      systemd.tmpfiles.settings."10-binary-cache"."/var/lib/binary-cache".v = {
        user = config.users.users.hydra-queue-runner.name;
        group = config.users.groups.nginx.name;
        mode = "750";
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

      nix.distributedBuilds = true;
      nix.buildMachines = [
        {
          hostName = "localhost";
          protocol = null; # only works with "localhost" builder
          inherit (pkgs.stdenv.hostPlatform) system;
          supportedFeatures = config.nix.settings.system-features or [ ];
          maxJobs = 24;
        }
        {
          hostName = "broccoli.internal";
          protocol = "ssh"; # ssh-ng not supported by hydra (see https://github.com/NixOS/hydra/blob/18c0d762109549351ecf622cde34514351a72492/src/hydra-queue-runner/build-remote.cc#L375)
          sshUser = "builder";
          sshKey = config.sops.secrets.ssh_remote_build.path;
          system = "aarch64-linux";
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSURWckhkcmFaL3lVWWpBeFQ5c1psZUJQNVY2eTI5QlY0ajFFbEJWSUZSYWogcm9vdEBicm9jY29saQo=";
          maxJobs = 8;
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
