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
      nixpkgs.buildPlatform = config.nixpkgs.hostPlatform;
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.recovery.targetDisk = "/dev/mmcblk0";

      hardware.firmware = [ (pkgs.extractLinuxFirmwareDirectory "rtl_nic") ];
    }
    {
      services.kodi.enable = true;
    }
  ];
}
