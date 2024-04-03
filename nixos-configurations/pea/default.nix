{ pkgs, ... }:
{
  imports = [ ./base.nix ];

  custom.server.enable = true;

  networking.wireless.iwd.enable = true;

  # needed for bcm4329 wifi
  hardware.firmware = [ pkgs.linux-firmware ];

  # systemd.services.otg-ethernet = {
  #   serviceConfig = {
  #     Type = "simple";
  #     RemainAfterExit = true;
  #     ExecStart = "${pkgs.gt}/bin/gt load ${./eth.scheme} ecm";
  #     ExecStop = "${pkgs.gt}/bin/gt rm -rf ecm";
  #   };
  #   description = [ "Load ethernet gadget scheme" ];
  #   requires = [ "sys-kernel-config.mount" ];
  #   after = [ "sys-kernel-config.mount" ];
  #   wantedBy = [ "usb-gadget.target" ];
  # };

  hardware.deviceTree.overlays = [
    {
      name = "usb-host-mode";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
          compatible = "sinovoip,bpi-m2-zero";
        };

        &usb_otg {
          dr_mode = "host";
          status = "okay";
        };
      '';
    }
  ];

  systemd.services.camera-stream = {
    path = [ pkgs.ffmpeg-headless ];
    serviceConfig = {
      ExecStart = "ffmpeg -f v4l2 -i /dev/video1 -pix_fmt yuv420p -preset ultrafast -b:v 600k -f rtsp rtsp://localhost:8554/stream";
      DynamicUser = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      DeviceAllow = "/dev/video*";
    };
  };
}
