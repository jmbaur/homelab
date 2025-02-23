{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    {
      hardware.cn9130-cf-pro.enable = true;

      # qualcom wifi card
      hardware.firmware = [ (pkgs.extractLinuxFirmwareDirectory "ath10k") ];
    }

    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-f06e0000.mmc";
    }
  ];
}
