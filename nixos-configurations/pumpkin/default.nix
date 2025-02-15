{ config, lib, ... }:

{
  config = lib.mkMerge [
    {
      hardware.macchiatobin.enable = true;

      custom.recovery.targetDisk = "/dev/disk/by-path/platform-f06e0000.mmc";
      custom.server.enable = true;
      custom.basicNetwork.enable = true;

      fileSystems."/var" = {
        fsType = "btrfs";
        device = "/dev/disk/by-partlabel/data";
        options = [
          "compress=zstd"
          "defaults"
          "noatime"
          "subvol=/data"
        ];
      };

      # This machine has many interfaces, and we currently only care that one
      # has an "online" status.
      systemd.network.wait-online.anyInterface = true;
    }
    {
      custom.yggdrasil.nodes.rhubarb.allowedTCPPorts = [
        config.services.navidrome.settings.Port
      ];

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
        originalsPath = "/var/lib/photoprism-photos";
      };
    }
    {
      custom.yggdrasil.nodes.rhubarb.allowedTCPPorts = [
        8096
      ];

      services.jellyfin.enable = true;
    }
  ];
}
