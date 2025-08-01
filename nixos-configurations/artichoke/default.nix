{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = true;

      boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "usbhid"
        "uas"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      hardware.firmware = [
        (pkgs.extractLinuxFirmwareDirectory "i915")
        (pkgs.extractLinuxFirmwareDirectory "rtl_nic")
      ];
    }
    {
      custom.server.enable = true;

      # TODO(jared): bonding
      custom.basicNetwork.enable = true;

      custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:00:15.0-usb-0:4:1.0-scsi-0:0:0:0";

      custom.backup.receiver.enable = true;
      custom.backup.sender.enable = false;

      custom.yggdrasil.allKnownPeers.allowedTCPPorts = [ config.custom.backup.receiver.port ];

      boot.initrd.luks.devices = {
        bigdisk1 = {
          device = "/dev/disk/by-path/pci-0000:00:12.0-ata-1.0";
          tryEmptyPassphrase = true;
          allowDiscards = config.services.fstrim.enable;
        };
        bigdisk2 = {
          device = "/dev/disk/by-path/pci-0000:00:12.0-ata-2.0";
          tryEmptyPassphrase = true;
          allowDiscards = config.services.fstrim.enable;
        };
      };

      fileSystems."/var" = {
        fsType = "btrfs";
        device = "/dev/mapper/bigdisk1";
        options = [
          "compress=zstd"
          "defaults"
          "noatime"
          "subvol=/data"
        ];
      };
    }
  ];
}
