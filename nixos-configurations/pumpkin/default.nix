{ lib, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      hardware.deviceTree.name = "marvell/armada-8040-mcbin.dtb";
    }
    {
      custom.image = {
        boot.uefi.enable = true;
        installer.targetDisk = "/dev/nvme0n1"; # TODO(jared): be more specific
      };
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
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
        enable = false;
        address = "[::]";
        originalsPath = "/data/photos";
      };
    }
    {
      services.jellyfin.enable = false;
    }
  ];
}
