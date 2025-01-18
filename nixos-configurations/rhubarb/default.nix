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
      custom.common.nativeBuild = true;
      custom.recovery.targetDisk = "/dev/mmcblk0";

      services.kodi.enable = true;
    }
  ];
}
