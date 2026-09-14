{
  config,
  lib,
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
      # Ensure our build machine doesn't attempt to use itself as a substituter
      nix.settings.substituters = lib.mkForce [ "https://cache.nixos.org" ];
      nix.settings.extra-substituters = lib.mkForce [ ];

      services.hydra-queue-builder-dev = {
        enable = true;
        queueRunnerAddr = "http://kale.internal:50051";
        settings = {
          maxJobs = 8;
          supportedFeatures = config.nix.settings.system-features or [ ];
        };
      };
    }
  ];
}
