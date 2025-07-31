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
      nixpkgs.buildPlatform = config.nixpkgs.hostPlatform;
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.recovery.targetDisk = "/dev/mmcblk0";

      hardware.firmware = [ (pkgs.extractLinuxFirmwareDirectory "rtl_nic") ];

      boot.initrd.availableKernelModules = [ "sdhci_pci" ];
    }
    {
      services.kodi.enable = true;

      hardware.graphics.extraPackages = with pkgs; [
        (intel-vaapi-driver.override { enableHybridCodec = true; })
        intel-media-driver
      ];
    }
  ];
}
