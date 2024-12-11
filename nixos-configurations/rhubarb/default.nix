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
      custom.nativeBuild = true;
      custom.image = {
        installer.targetDisk = "/dev/mmcblk0";
        boot.uefi.enable = true;
      };

      services.kodi.enable = true;
    }
  ];
}
