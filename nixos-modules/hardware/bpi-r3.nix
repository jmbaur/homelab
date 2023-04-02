{ config, lib, pkgs, ... }: {
  options.hardware.bpi-r3.enable = lib.mkEnableOption "bananapi r3";
  config = lib.mkIf config.hardware.bpi-r3.enable {
    boot.kernelPackages = pkgs.linuxPackages_testing; # only available in kernel >= 6.3-rc1

    hardware.deviceTree.enable = true;
    hardware.deviceTree.name = "mt7986a-bananapi-bpi-r3.dtb";
    hardware.deviceTree.overlays = [
      {
        name = "mt7986a-bananapi-bpi-r3-emmc.dtbo";
        dtboFile = "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-emmc.dtbo";
      }
      {
        name = "mt7986a-bananapi-bpi-r3-nand.dtbo";
        dtboFile = "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-nand.dtbo";
      }
      {
        name = "mt7986a-bananapi-bpi-r3-nor.dtbo";
        dtboFile = "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-nor.dtbo";
      }
      {
        name = "mt7986a-bananapi-bpi-r3-sd.dtbo";
        dtboFile = "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-sd.dtbo";
      }
    ];

    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
  };
}
