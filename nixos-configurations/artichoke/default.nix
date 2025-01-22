{
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = true;
      hardware.enableRedistributableFirmware = true;

      boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      hardware.firmware = [
        (pkgs.extractLinuxFirmware "i915-firmware" [
          "i915/bxt_dmc_ver1_07.bin"
        ])
      ];
    }
    {
      custom.server.enable = true;

      # TODO(jared): bonding
      custom.basicNetwork.enable = true;

      custom.recovery.targetDisk = "/dev/disk/by-path/pci-0000:00:15.0-usb-0:4:1.0-scsi-0:0:0:0";

      # fileSystems."/var" = {
      #   fsType = "btrfs";
      #   device = "/dev/disk/by-partlabel/data";
      #   options = [
      #     "compress=zstd"
      #     "defaults"
      #     "noatime"
      #     "subvol=/data"
      #   ];
      # };
      # /dev/disk/b-path/pci-0000:00:12.0-ata-1.0
      # /dev/disk/b-path/pci-0000:00:12.0-ata-2.0
    }
  ];
}
