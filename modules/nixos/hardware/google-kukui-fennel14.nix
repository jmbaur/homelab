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

    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.initrd.availableKernelModules = [
      "ath"
      "ath10k_core"
      "ath10k_pci"
      "ath10k_sdio"
      "cros_ec_lid_angle"
      "cros_ec_rpmsg"
      "cros_ec_sensorhub"
      "cros_ec_sensors_core"
      "cros_ec_typec"
      "drm"
      "mtk_rpmsg"
      "mtk_scp"
      "mtk_scp_ipi"
    ];
  };
}
