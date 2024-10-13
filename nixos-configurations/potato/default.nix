{
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      hardware.cpu.intel.updateMicrocode = true;
      hardware.chromebook = {
        enable = true;
        laptop = false;
      };

      boot.initrd.availableKernelModules = [
        "nvme"
        "sd_mod"
        "usb_storage"
        "xhci_pci"
      ];
      boot.initrd.kernelModules = [ "i915" ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      tinyboot = {
        enable = false; # TODO
        board = "fizz-fizz";
      };

      hardware.graphics.extraPackages = with pkgs; [
        (intel-vaapi-driver.override { enableHybridCodec = true; })
        intel-media-driver
      ];

      hardware.firmware = [
        pkgs.linux-firmware
        pkgs.sof-firmware
      ];

      # Force AVS driver since the kernel will use the SKL driver by default.
      # https://github.com/WeirdTreeThing/chromebook-linux-audio/blob/99eef5cc3d2f82f451c34764f230f3d5d22239cf/setup-audio#L113
      boot.extraModprobeConfig = ''
        options snd-intel-dspcfg dsp_driver=4
        options snd-soc-avs ignore_fw_version=1
      '';

      services.pipewire.wireplumber.configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-hdmi-output.conf" ''
          wireplumber.settings = {
            device.restore-profile = false
          }
          monitor.alsa.rules = [
            {
              matches = [
                {
                  device.name = "alsa_card.platform-avs_hdaudio.2"
                }
              ]
              actions = {
                update-props = {
                  device.profile = "pro-audio"
                  device.description = "HDMI Output"
                  priority.session = 600
                }
              }
            }
          ]
        '')
      ];
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;

      custom.image = {
        boot.uefi.enable = true;
        installer.targetDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
      };

      boot.kernelParams = [ "console=ttyS0,115200" ];
      systemd.services."serial-getty@ttyS0" = {
        enable = true;
        wantedBy = [ "getty.target" ];
        serviceConfig.Restart = "always"; # restart when session is closed
      };

      services.kodi.enable = true;
    }
  ];
}
