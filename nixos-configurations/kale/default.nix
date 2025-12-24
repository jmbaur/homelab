{
  config,
  lib,
  pkgs,
  ...
}:
let
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

      nixpkgs.config.allowUnfree = true;
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        nvidiaSettings = false;
        open = false;
      };

      boot.kernel.sysfs.devices.system.cpu = lib.listToAttrs (
        lib.genList (x: {
          name = "cpu${toString x}";
          value.cpufreq.scaling_governor = "powersave";
        }) 24
      );
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:41:00.0-nvme-1";

      # nix.settings.netrc-file = config.sops.secrets.hydra_netrc.path;

      nix.settings.allowed-uris = [
        "https://"
        "github:"
      ];

      zramSwap.memoryPercent = 200;

      system.stateVersion = "26.05";

      services.hydra = {
        enable = true;
        # logo = ./dr-doom.svg;
        hydraURL = "https://hydra.jmbaur.com";
        notificationSender = "hydra@localhost";
        useSubstitutes = true;
        extraConfig = ''
          allow_import_from_derivation = false
          binary_cache_public_uri = https://cache.jmbaur.com
          log_prefix = https://cache.jmbaur.com/
        '';
      };

      nix.distributedBuilds = true;
      nix.buildMachines = [
        {
          hostName = "localhost";
          protocol = null; # only works with "localhost" builder
          inherit (pkgs.stdenv.hostPlatform) system;
          supportedFeatures = config.nix.settings.system-features or [ ];
          maxJobs = 4;
        }
      ];

      # services.nginx.virtualHosts."hydra.jmbaur.com" = {
      #   onlySSL = true;
      #   locations."/".proxyPass = "http://[::1]:3000";
      #   sslCertificate = config.sops.secrets."cf-origin/cert".path;
      #   sslCertificateKey = config.sops.secrets."cf-origin/key".path;
      # };
    }
  ];
}
