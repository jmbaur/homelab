{ lib, pkgs, ... }:

{
  config = lib.mkMerge [
    {
      hardware.rpi4.enable = true;

      custom.server.enable = true;
      custom.basicNetwork.enable = true;

      # NOTE: This might change depending on which USB port we plug into. This
      # is the bottom USB3 port.
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:2:1.0-scsi-0:0:0:0";
    }
    {
      services.kodi.enable = true;

      services.pipewire.wireplumber.configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-hdmi-output.conf" ''
          wireplumber.settings = {
            device.restore-profile = false
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
  ];
}
