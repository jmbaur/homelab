{ config, lib, pkgs, ... }: {
  options.hardware.bpi-r3 = {
    enable = lib.mkEnableOption "bananapi r3";
  };

  config = lib.mkIf config.hardware.bpi-r3.enable {
    boot.kernelPackages = pkgs.linuxPackages_latest;

    boot.kernelParams = [ "console=ttyS0,115200" ];

    # u-boot looks for $fdtfile on the ESP at /dtb
    boot.loader.systemd-boot.extraFiles."dtb" = config.hardware.deviceTree.package;
    boot.loader.grub.extraFiles."dtb" = config.hardware.deviceTree.package;

    hardware.deviceTree.enable = true;
    hardware.deviceTree.name = "mediatek/mt7986a-bananapi-bpi-r3.dtb";
    hardware.deviceTree.overlays = map
      (dtboFile: {
        inherit dtboFile;
        name = builtins.baseNameOf dtboFile;
      }) [
      "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-nand.dtbo"
      "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-emmc.dtbo"
    ];
  };
}
