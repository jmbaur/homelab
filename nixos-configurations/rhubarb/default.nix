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
      custom.recovery.targetDisk = "/dev/sda"; # TODO(jared): refine this
    }
    {
      services.kodi.enable = false;
    }
  ];
}
