{ config, lib, pkgs, ... }:
with lib;
{
  options.hardware.kukui-fennel14 = {
    enable = mkEnableOption "google kukui-fennel14 board";
  };
  config = mkIf config.hardware.kukui-fennel14.enable {
    custom.laptop.enable = true;
    services.xserver.xkbOptions = "ctrl:swap_lwin_lctl";

    hardware.bluetooth.enable = mkDefault true;
    hardware.enableRedistributableFirmware = true;
    hardware.deviceTree = {
      enable = true;
      filter = "mt8183-kukui-jacuzzi-fennel14.dtb";
    };

    boot.initrd.kernelModules = [
      "cros_ec"
      "cros_ec_keyb"
      "cros_ec_typec"
      "drm"
      "mediatek_drm"
      "panfrost"
    ];

    boot.kernelPackages = pkgs.linuxKernel.packagesFor pkgs.linux_chromiumos_mediatek;
  };
}
