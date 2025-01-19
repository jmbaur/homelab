{ pkgs, ... }:
{
  # better support for mt7915 wifi card
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  hardware.firmware = [
    pkgs.wireless-regdb
    pkgs.mt7915-firmware
  ];

  hardware.armada-388-clearfog.enable = true;

  # TODO(jared): use FIT_BEST_MATCH feature in u-boot to choose this automatically
  hardware.deviceTree.name = "armada-388-clearfog-pro.dtb";

  custom = {
    server.enable = true;
    recovery.targetDisk = "/dev/disk/by-path/platform-f10a8000.sata-ata-1.0";
  };
}
