{
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.recovery.targetDisk = "/dev/mmcblk0";

      hardware.firmware = [
        (pkgs.extractLinuxFirmwareDirectory "rtl_nic")
        (pkgs.extractLinuxFirmwareDirectory "intel")
        pkgs.sof-firmware
      ];

      boot.initrd.availableKernelModules = [
        "sdhci_pci"
        "uas"
      ];

      # dsp_driver=3 == "use SOF"
      boot.extraModprobeConfig = ''
        options snd-intel-dspcfg dsp_driver=3
        options snd-soc-avs ignore_fw_version=1
      '';
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
