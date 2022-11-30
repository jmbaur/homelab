{ config, lib, pkgs, ... }:
with lib;
{
  options.hardware.kukui-fennel14 = {
    enable = mkEnableOption "google kukui-fennel14 board";
  };
  config = mkIf config.hardware.kukui-fennel14.enable {
    custom.laptop.enable = true;
    services.xserver.xkbOptions = "ctrl:swap_lwin_lctl";

    environment.pathsToLink = [ "/share/alsa" ];
    environment.systemPackages = [
      # https://chromium.googlesource.com/chromiumos/overlays/board-overlays/+/refs/heads/main/overlay-jacuzzi/chromeos-base/chromeos-bsp-jacuzzi/files/fennel14/audio/ucm-config
      (pkgs.runCommand "google-kukui-fennel14-alsa-ucm" { } ''
        mkdir -p $out/share/alsa/ucm/{mt8183_mt6358_ts3a227_rt1015p.fennel14,mt8183_da7219_rt1015p.fennel14}
        cp ${./HiFi.conf} $out/share/alsa/ucm/mt8183_da7219_rt1015p.fennel14/HiFi.conf
        cp ${./mt8183_da7219_rt1015p.conf} $out/share/alsa/ucm/mt8183_da7219_rt1015p.fennel14/mt8183_da7219_rt1015p.fennel14.conf
        cp ${./HiFi_mt6358.conf} $out/share/alsa/ucm/mt8183_mt6358_ts3a227_rt1015p.fennel14/HiFi.conf
        cp ${./mt8183_mt6358_ts3a227_rt1015p.conf} $out/share/alsa/ucm/mt8183_mt6358_ts3a227_rt1015p.fennel14/mt8183_mt6358_ts3a227_rt1015p.fennel14.conf
      '')
    ];

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
