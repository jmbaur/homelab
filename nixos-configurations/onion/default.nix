{ lib, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "armv7l-linux";
      hardware.deviceTree.name = "marvell/kirkwood-netgear_readynas_duo_v2.dtb";
    }
    {
      custom.server.enable = true;
      custom.recovery.targetDisk = "/dev/TODO";
    }
  ];
}
