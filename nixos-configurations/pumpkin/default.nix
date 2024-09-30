{ lib, ... }:
{
  config = lib.mkMerge [
    {
      hardware.macchiatobin.enable = true;

      custom.image = {
        boot.uefi.enable = true;
        installer.targetDisk = "/dev/disk/by-path/platform-f2600000.pcie-pci-0000:01:00.0-nvme-1";
      };
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.nativeBuild = true;
    }
    {
      services.navidrome = {
        enable = true;
        settings = {
          Address = "[::]";
          Port = 4533;
          DefaultTheme = "Auto";
        };
      };
    }
    {
      services.photoprism = {
        enable = true;
        address = "[::]";
        originalsPath = "/data/photos";
      };
    }
    {
      services.jellyfin.enable = true;
    }
  ];
}
