{
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    {
      hardware.rpi4.enable = true;
      boot.kernelPackages = pkgs.linuxPackages_6_12;

      custom.server.enable = true;
      custom.basicNetwork.enable = true;

      # NOTE: This might change depending on which USB port we plug into. This
      # is the bottom USB3 port.
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:2:1.0-scsi-0:0:0:0";
    }
    {
      services.kodi.enable = true;
    }
  ];
}
