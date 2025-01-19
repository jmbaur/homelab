{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  hardware.firmware = [
    pkgs.wireless-regdb
    (pkgs.extractLinuxFirmware "mt7915-firmware"
      # https://github.com/torvalds/linux/blob/fda5e3f284002ea55dac1c98c1498d6dd684046e/drivers/net/wireless/mediatek/mt76/mt7915/mt7915.h#L29
      [
        "mediatek/mt7915_wa.bin"
        "mediatek/mt7915_wm.bin"
        "mediatek/mt7915_rom_patch.bin"
        "mediatek/mt7916_wa.bin"
        "mediatek/mt7916_wm.bin"
        "mediatek/mt7916_rom_patch.bin"
        "mediatek/mt7981_wa.bin"
        "mediatek/mt7981_wm.bin"
        "mediatek/mt7981_rom_patch.bin"
        "mediatek/mt7986_wa.bin"
        "mediatek/mt7986_wm.bin"
        "mediatek/mt7986_wm_mt7975.bin"
        "mediatek/mt7986_rom_patch.bin"
        "mediatek/mt7986_rom_patch_mt7975.bin"
        "mediatek/mt7915_eeprom.bin"
        "mediatek/mt7915_eeprom_dbdc.bin"
        "mediatek/mt7916_eeprom.bin"
        "mediatek/mt7981_eeprom_mt7976_dbdc.bin"
        "mediatek/mt7986_eeprom_mt7975.bin"
        "mediatek/mt7986_eeprom_mt7975_dual.bin"
        "mediatek/mt7986_eeprom_mt7976.bin"
        "mediatek/mt7986_eeprom_mt7976_dbdc.bin"
        "mediatek/mt7986_eeprom_mt7976_dual.bin"
      ]
    )
  ];

  hardware.armada-388-clearfog.enable = true;

  # TODO(jared): use FIT_BEST_MATCH feature in u-boot to choose this automatically
  hardware.deviceTree.name = "armada-388-clearfog-pro.dtb";

  custom = {
    server.enable = true;
    recovery.targetDisk = "/dev/disk/by-path/platform-f10a8000.sata-ata-1.0";
  };
}
