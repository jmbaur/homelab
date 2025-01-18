{ pkgs, ... }:
{
  # needed for mt7915 firmware
  hardware.firmware = [ pkgs.linux-firmware ];

  hardware.armada-388-clearfog.enable = true;

  # TODO(jared): use FIT_BEST_MATCH feature in u-boot to choose this automatically
  hardware.deviceTree.name = "armada-388-clearfog-pro.dtb";

  custom = {
    server.enable = true;
    recovery.targetDisk = "/dev/disk/by-path/platform-f10a8000.sata-ata-1";
  };
}
