{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      hardware.deviceTree.name = "marvell/armada-8040-mcbin.dtb";
      system.build.firmware = pkgs.mcbin-firmware;
    }
    {
      custom.image = {
        boot.uefi.enable = true;
        installer.targetDisk = "/dev/nvme0n1"; # TODO(jared): be more specific
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
