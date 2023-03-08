{ config, lib, pkgs, ... }:
with lib;
{
  options.hardware.kukui-fennel14 = {
    enable = mkEnableOption "google kukui-fennel14 board";
  };
  config = mkIf config.hardware.kukui-fennel14.enable {
    custom.laptop.enable = true;

    environment.pathsToLink = [ "/share/alsa" ];
    environment.systemPackages = [
      # https://chromium.googlesource.com/chromiumos/overlays/board-overlays/+/refs/heads/main/overlay-jacuzzi/chromeos-base/chromeos-bsp-jacuzzi/files/fennel14/audio/ucm-config
      # https://github.com/hexdump0815/imagebuilder/tree/main/systems/chromebook_kukui/extra-files/usr/share/alsa/ucm2/mt8183_da7219_r
      (pkgs.linkFarm "google-kukui-fennel14-alsa-ucm" (map
        (path: {
          name = "share/alsa/ucm2/mt8183_da7219_r/${baseNameOf path}";
          inherit path;
        }) [ ./HiFi.conf ./mt8183_da7219_rt1015p.conf ]))
    ];

    hardware.chromebook.enable = true;
    hardware.bluetooth.enable = mkDefault true;
    hardware.enableRedistributableFirmware = true;
    hardware.deviceTree = {
      enable = true;
      filter = "mt8183-kukui-jacuzzi-fennel14*.dtb";
    };

    boot.kernelPackages = pkgs.linuxKernel.packagesFor pkgs.linux_mediatek;
  };
}
