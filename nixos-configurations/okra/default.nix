{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ "${modulesPath}/installer/scan/not-detected.nix" ];

  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      boot.kernelModules = [ "kvm-amd" ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/b1ef9f57-124b-487a-a14b-453c76b08623";
        fsType = "btrfs";
        options = [
          "compress=zstd"
          "noatime"
          "discard=async"
        ];
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/57B7-D82A";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
          "x-systemd.automount"
          "x-systemd.idle-timeout=2min"
        ];
      };

      zramSwap.enable = true;

      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    }
    {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      custom.dev.enable = true;
      custom.desktop.enable = true;
      custom.recovery.enable = false;
      custom.backup.sender.enable = false;
      services.yggdrasil.enable = false;

      virtualisation.podman.enable = true;

      nix.settings = {
        extra-substituters = [ "https://cache.northwood.space" ];
        extra-trusted-public-keys = [
          "cache.northwood.space-1:aS//R1OH2ct1xKquarzaEWRW21gDJ9pRyM8zUgvhBbc="
        ];
      };
    }
  ];
}
