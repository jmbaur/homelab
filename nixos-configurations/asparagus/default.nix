{ lib, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      hardware.deviceTree.name = "qcom/sc7180-trogdor-wormdingler-rev1-boe.dtb";

      hardware.chromebook.trogdor.enable = true;

      custom.dont-use-me-chromeos-partition.enable = true;

      # TODO(jared): resolve conflict between systemd-boot and tinyboot.
      boot.loader.systemd-boot.enable = false;

      boot.loader.tinyboot = {
        enable = true;
        # platform.qualcomm = true;
        # chromebook = true;
        # efi = true;
        # linux.kconfig = with lib.kernel; {
        #   HID_GOOGLE_HAMMER = yes;
        #   I2C_CROS_EC_TUNNEL = yes;
        #   I2C_HID_OF = yes;
        #   KEYBOARD_CROS_EC = yes;
        #   LEDS_CLASS = yes;
        #   NEW_LEDS = yes;
        # };
      };

      services.evremap.settings = {
        device_name = lib.mkForce "Google Inc. Hammer";
        phys = "usb-xhci-hcd.0.auto-1.3/input0";
      };
    }
    {
      custom.desktop.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-7c4000.mmc";

    }
  ];
}
