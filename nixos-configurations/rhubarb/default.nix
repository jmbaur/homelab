{
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
      boot.kernelPatches = [
        {
          name = "media/i2c: Add a driver for the Sony IMX708 image sensor";
          patch = pkgs.fetchpatch {
            url = "https://github.com/raspberrypi/linux/commit/9bbe36729058ba8ca2ee8cdd99b3e459211f81fe.patch";
            excludes = [ "drivers/media/i2c/Makefile" ];
            hash = "sha256-MgxZLpWSztSI3TEO5K05KDaVU4hAvnIaaixhJ0r4K00=";
          };
        }
        {
          # The patch from above doesn't apply cleanly to drivers/media/i2c/Makefile, do the change here instead.
          name = "add imx708 to makefile";
          patch = ./imx708-makefile.patch;
        }
        {
          name = "media: i2c: imx708: Fix lockdep issues.";
          patch = pkgs.fetchpatch {
            url = "https://github.com/raspberrypi/linux/commit/96f6b239ff694192416df9cc3f8e130fb7b19301.patch";
            hash = "sha256-KHQnpwukO7WU5CZptu9gcoqrV8j/Yh/K13sEj7QxrII=";
          };
        }
        {
          name = "media: i2c: Tweak default PDAF gain table in imx708 driver";
          patch = pkgs.fetchpatch {
            url = "https://github.com/raspberrypi/linux/commit/686f5708baaafb35e03e6e56396339330d0fec48.patch";
            hash = "sha256-6W8cCJMDRUBaVGynojWCkbCXKAvmkUHWRi29XWESMWk=";
          };
        }
      ];

      hardware.deviceTree.overlays = [
        # {
        #     name = "imx708.dtbo";
        #     dtboFile = "${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/imx708.dtbo";
        # }
      ];

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

      services.yggdrasil.settings.Peers = [ "tls://celery.jmbaur.com:443" ];

      custom.yggdrasil.peers.pumpkin.allowedTCPPorts = [ 8080 ];
    }
  ];
}
