{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.hardware.chromebook.trogdor.enable = lib.mkEnableOption "trogdor";

  config = lib.mkIf config.hardware.chromebook.trogdor.enable {
    boot.kernelParams = [ "deferred_probe_timeout=30" ];

    boot.kernelPackages = pkgs.linuxPackages_6_12;
    boot.kernelPatches = [
      {
        name = "trogdor-hardware-enablement";
        patch = null;
        extraStructuredConfig = {
          RMI4_F11 = lib.kernel.yes;
          RMI4_F12 = lib.kernel.yes;
          RMI4_F30 = lib.kernel.yes;
          RMI4_F34 = lib.kernel.yes;
          RMI4_F3A = lib.kernel.yes;
          RMI4_F55 = lib.kernel.yes;
          RMNET = lib.kernel.yes;
          QRTR = lib.kernel.yes;
        };
      }
    ];

    boot.initrd.availableKernelModules = [
      "i2c-hid-of"
      "i2c-hid-of-goodix"
      "elan-i2c"
      "elants-i2c"
      "cros-ec-keyb"
      "sbs-battery"
    ];

    boot.initrd.systemd.services.adjust-storage-iommu = {
      wantedBy = [ "initrd.target" ];
      before = [ "initrd-fs.target" ];
      script = ''
        # This script relaxes iommu for the devices, relaxing memory
        # protection, but we consider it a fine tradeoff because those
        # hardware blocks don't have firmware on them.

        # It Increases eMMC speed by 15% according to gnome disks benchmark
        # with sample size 1000 MiB and number of samples 2.

        iommus="
          /sys/devices/platform/soc@0/7c4000.mmc/iommu_group/type
          /sys/devices/platform/soc@0/8804000.mmc/iommu_group/type
          /sys/devices/platform/soc@0/a6f8800.usb/a600000.usb/iommu_group/type
        "

        for iommu in $iommus; do
          [ -f "$iommu" ] && echo "DMA-FQ" > "$iommu"
        done
      '';
    };

  };
}
