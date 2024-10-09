{ lib, ... }:
{
  imports = [
    ./router.nix
    ./web.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  hardware.bpi-r3.enable = true;

  hardware.deviceTree.overlays = [
    {
      name = "real-time-clock";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
          compatible = "bananapi,bpi-r3";
        };

        &i2c0 {
          rtc@68 {
              compatible = "nxp,pcf8523";
              reg = <0x68>;
              quartz-load-femtofarads = <7000>;
          };
        };
      '';
    }
  ];

  # Make the pcf8523 driver builtin so we dont' run into issues such as this:
  # https://github.com/systemd/systemd/issues/17737
  boot.kernelPatches = [
    {
      name = "rtc";
      patch = null;
      extraStructuredConfig.RTC_DRV_PCF8523 = lib.kernel.yes;
    }
  ];

  custom.server.enable = true;

  custom.image = {
    installer.targetDisk = "/dev/disk/by-path/platform-11230000.mmc";
    boot.uefi.enable = true;
  };
}
