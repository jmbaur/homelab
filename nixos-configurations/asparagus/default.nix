{ lib, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      hardware.deviceTree.name = "qcom/sc7180-trogdor-wormdingler-rev1-boe.dtb";

      hardware.chromebook.trogdor.enable = true;

      custom.dont-use-me-chromeos-partition.enable = true;

      # TODO(jared): resolve conflict between systemd-boot and tinyboot.
      boot.loader.systemd-boot.enable = false;

      tinyboot = {
        enable = true;
        board = "trogdor-wormdingler";
      };
    }
    {
      custom.desktop.enable = true;
      custom.recovery.targetDisk = "/dev/mmcblk0"; # TODO(jared): refine this
    }
  ];
}
