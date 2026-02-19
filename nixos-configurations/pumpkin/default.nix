{ config, lib, ... }:

{
  config = lib.mkMerge [
    {
      # TODO(jared): a bunch of media-related pacakges don't cross-compile
      nixpkgs.buildPlatform = config.nixpkgs.hostPlatform;

      hardware.macchiatobin.enable = true;

      custom.recovery.targetDisk = "/dev/disk/by-path/platform-f06e0000.mmc";
      custom.server = {
        enable = true;
        interfaces.pumpkin-0.matchConfig.Path = "platform-f2000000.ethernet";
      };

      # This machine has many interfaces, and we currently only care that one
      # has an "online" status.
      systemd.network.wait-online.anyInterface = true;
    }
  ];
}
