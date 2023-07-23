{ config, lib, pkgs, ... }: {
  options.hardware.bpi-r3.enable = lib.mkEnableOption "bananapi r3";
  config = lib.mkIf config.hardware.bpi-r3.enable {
    boot.kernelPackages = pkgs.linuxPackages_latest;

    hardware.deviceTree.enable = true;
    hardware.deviceTree.name = "mediatek/mt7986a-bananapi-bpi-r3.dtb";
    hardware.deviceTree.overlays = [
      {
        name = "mt7986a-bananapi-bpi-r3-nand.dtbo";
        dtboFile = "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-nand.dtbo";
      }
      {
        name = "mt7986a-bananapi-bpi-r3-sd.dtbo";
        dtboFile = "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-sd.dtbo";
      }
    ];
  };
}
