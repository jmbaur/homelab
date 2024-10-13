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
        enable = true;
        board = "fizz-fizz";
      };

      hardware.graphics.extraPackages = with pkgs; [
        (intel-vaapi-driver.override { enableHybridCodec = true; })
        intel-media-driver
      ];

      hardware.firmware = [ pkgs.linux-firmware ];

      # Force AVS driver since the kernel will use the SKL driver by default.
      # https://github.com/WeirdTreeThing/chromebook-linux-audio/blob/99eef5cc3d2f82f451c34764f230f3d5d22239cf/setup-audio#L113
      boot.extraModprobeConfig = ''
        options snd-intel-dspcfg dsp_driver=4
        options snd-soc-avs ignore_fw_version=1
      '';
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;

      custom.image = {
        boot.bootLoaderSpec.enable = true;
        installer.targetDisk = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1";
        mutableNixStore = true; # TODO(jared): set to false
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
