{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      hardware.enableRedistributableFirmware = true;
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
