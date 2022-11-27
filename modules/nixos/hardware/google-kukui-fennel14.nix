{ config, lib, pkgs, ... }:
with lib;
{
  options.hardware.kukui-fennel14 = {
    enable = mkEnableOption "google kukui-fennel14 board";
  };
  config = mkIf config.hardware.kukui-fennel14.enable {
    custom.laptop.enable = true;
    services.xserver.xkbOptions = "ctrl:swap_lwin_lctl";

    hardware.enableRedistributableFirmware = true;
    hardware.deviceTree = {
      enable = true;
      filter = "mt8183-kukui-jacuzzi-fennel14.dtb";
    };

    boot.initrd.availableKernelModules = [
      "ath10k_pci"
      "cros_ec"
      "cros_ec_keyb"
      "cros_ec_lid_angle"
      "cros_ec_rpmsg"
      "cros_ec_sensorhub"
      "cros_ec_sensors_core"
      "cros_ec_typec"
      "cros_usbpd_charger"
      "drm"
      "mediatek_drm"
      "mtk_rpmsg"
      "mtk_scp"
      "mtk_scp_ipi"
    ];

    boot.kernelPackages = pkgs.recurseIntoAttrs
      (pkgs.linuxKernel.packagesFor (pkgs.linuxKernel.manualConfig {
        inherit (pkgs) lib stdenv;
        inherit (pkgs.linuxKernel.kernels.linux_6_0) version src;
        configfile = ./chromiumos-mediatek.config;
        allowImportFromDerivation = true;
      }));
  };
}
