{ pkgs, ... }: {
  imports = [ ./base.nix ];

  system.stateVersion = "23.11";

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

  systemd.services.camera-stream = {
    path = [ pkgs.ffmpeg-headless ];
    serviceConfig = {
      ExecStart = "ffmpeg -f v4l2 -i /dev/video0 -pix_fmt yuv420p -preset ultrafast -b:v 600k -f rtsp rtsp://localhost:8554/stream";
      DynamicUser = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      DeviceAllow = "/dev/video*";
    };
  };
}
