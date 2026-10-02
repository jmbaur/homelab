{ lib, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      hardware.cpu.amd.updateMicrocode = true;
      hardware.enableRedistributableFirmware = true;

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];

      boot.kernelModules = [ "kvm-amd" ];

      zramSwap.enable = true;

      boot.loader.systemd-boot.enable = true;

      fileSystems."/boot" = {
        device = "/dev/disk/by-partlabel/boot";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
          "x-systemd.automount"
          "x-systemd.idle-timeout=1"
        ];
      };

      fileSystems."/" = {
        device = "/dev/disk/by-partlabel/root";
        fsType = "btrfs";
        options = [
          "compress=zstd"
          "defaults"
          "noatime"
        ];
      };
    }
    {
      custom.basicNetwork.enable = true;
      custom.server.enable = true;
      custom.normalUser.enable = true;
      custom.dev.enable = true;
      custom.recovery.enable = false;

      systemd.network.networks."50-wired".dhcpV4Config.ClientIdentifier = "mac";
    }
  ];
}
