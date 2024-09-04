{ pkgs, ... }:
{
  imports = [ ./base.nix ];

  custom.server.enable = true;
  custom.basicNetwork.enable = true;

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
      name = "csi-enable";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
          compatible = "sinovoip,bpi-m2-zero";
        };

        &csi {
          status = "okay";

          // port {
          //   csi_ep: endpoint {
          //     remote-endpoint = <&ov2640_ep>;
          //     bus-width = <8>;
          //     hsync-active = <1>; /* Active high */
          //     vsync-active = <0>; /* Active low */
          //     data-active = <1>;  /* Active high */
          //     pclk-sample = <1>;  /* Rising */
          //   };
          // };
        };
      '';
    }
  ];

  systemd.services.camera-stream = {
    path = [ pkgs.ffmpeg-headless ];
    serviceConfig = {
      ExecStart = "ffmpeg -f v4l2 -i /dev/video1 -pix_fmt yuv420p -preset ultrafast -b:v 600k -f rtsp rtsp://[::1]:8554/stream";
      DynamicUser = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      DeviceAllow = "/dev/video*";
    };
  };
}
