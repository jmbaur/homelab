{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      hardware.blackrock.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-1c20000.pcie-pci-0002:01:00.0-nvme-1";

      # TODO(jared): doesn't work on wdk2023?
      systemd.services.pd-mapper.enable = false;
    }
    {
      sops.secrets = {
        nix = { };
        mirror = { };
      };

      services.harmonia = {
        enable = true;
        signKeyPaths = [ config.sops.secrets.nix.path ];
        settings.bind = "[::]:5000";
      };

      nix.settings.allow-import-from-derivation = false;

      nix.settings.allowed-uris = [
        "https://"
        "github:"
      ];

      zramSwap.memoryPercent = 200;

      systemd.services.hydra-evaluator.environment.GC_DONT_GC = "1"; # https://github.com/NixOS/nix/issues/4178#issuecomment-738886808

      services.hydra = {
        enable = true;
        hydraURL = "http://localhost:3000";
        notificationSender = "hydra@localhost";
        useSubstitutes = true;
      };

      # Allow all nodes to reach hydra
      custom.yggdrasil.all.allowedTCPPorts = [ 3000 ];

      nix.buildMachines = [
        {
          hostName = "localhost";
          protocol = null; # only works with "localhost" builder
          system = pkgs.stdenv.hostPlatform.system;
          supportedFeatures = config.nix.settings.system-features or [ ];
          maxJobs = 4;
        }
      ];

      nix.distributedBuilds = false;
    }
  ];
}
