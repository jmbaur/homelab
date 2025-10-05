{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    {
      nixpkgs.buildPlatform = "x86_64-linux";

      hardware.rpi4.enable = true;

      custom.server = {
        enable = true;
        interfaces.rhubarb-0.matchConfig.Path = "platform-fe300000.mmc";
      };

      custom.basicNetwork.enable = true;

      # NOTE: This might change depending on which USB port we plug into. This
      # is the bottom USB3 port.
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:2:1.0-scsi-0:0:0:0";
    }
    {
      services.pipewire.wireplumber.configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-hdmi-output.conf" ''
          wireplumber.settings = {
            device.restore-profile = false
            device.routes.default-sink-volume = 1.0 ^ 3
          }
          monitor.alsa.rules = [
            {
              matches = [
                {
                  node.name = "alsa_output.platform-fef00700.hdmi.hdmi-stereo"
                }
              ]
              actions = {
                update-props = {
                  priority.session = 600
                  priority.driver = 600
                }
              }
            }
          ]
        '')
      ];
    }
    {
      # NOTE: this makes the overlays option not work at all :/
      hardware.deviceTree = {
        name = "broadcom/bcm2711-rpi-4-b.dtb";
        package = lib.mkForce (
          pkgs.runCommand "device-tree-package"
            {
              nativeBuildInputs = [ pkgs.buildPackages.libraspberrypi ];
            }
            ''
              mkdir -p $out/broadcom
              dtmerge ${config.hardware.deviceTree.kernelPackage}/dtbs/broadcom/bcm2711-rpi-4-b.dtb $out/broadcom/bcm2711-rpi-4-b.dtb ${config.hardware.deviceTree.kernelPackage}/dtbs/overlays/imx708.dtbo
            ''
        );
      };

      networking.wireless.iwd.enable = true;
      environment.systemPackages = [ pkgs.iw ];

      systemd.sockets.garage-door = {
        listenStreams = [ "[::]:8080" ];
        wantedBy = [ "sockets.target" ];
      };

      systemd.services.garage-door.serviceConfig.ExecStart = toString [
        (lib.getExe pkgs.homelab-garage-door)
        "/dev/gpiochip0"
        "23" # set
        "24" # unset
      ];

      services.mediamtx = {
        enable = true;
        allowVideoAccess = true;
        settings.paths.cam = {
          source = "udp://127.0.0.1:3333";
          runOnInit = "${pkgs.rpicam-apps}/bin/rpicam-vid -n -t 0 --codec libav --libav-format mpegts -o udp://127.0.0.1:3333";
          runOnInitRestart = true;
        };
      };

      services.yggdrasil.settings.Peers = [ "tls://celery.jmbaur.com:443" ];

      custom.yggdrasil.peers.pumpkin.allowedTCPPorts = [
        8080 # homelab-garage-door
        8889 # webrtc mediamtx
      ];
    }
  ];
}
