{ config, lib, ... }:

{
  imports = [ ./router.nix ];

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
  custom.basicNetwork.enable = !config.router.enable;
  custom.recovery.targetDisk = "/dev/disk/by-path/platform-11230000.mmc";

  # hostapd tuning config
  services.hostapd = {
    radios.wlan0 = {
      band = "2g";
      countryCode = "US";
      wifi5.enable = false;
      wifi6.enable = false;
      wifi7.enable = false;
      wifi4 = {
        enable = true;
        capabilities = [
          "RXLDPC"
          "HT40+"
          "GF"
          "SHORT-GI-20"
          "SHORT-GI-40"
          "TX-STBC"
          "RX-STBC1"
          "MAX-AMSDU-7935"
        ];
      };
    };
    radios.wlan1 = {
      band = "5g";
      countryCode = "US";
      wifi7.enable = false;
      wifi4 = {
        enable = true;
        capabilities = [
          "RXLDPC"
          "HT40+"
          "GF"
          "SHORT-GI-20"
          "SHORT-GI-40"
          "TX-STBC"
          "RX-STBC1"
          "MAX-AMSDU-7935"
        ];
      };
      wifi5 = {
        enable = true;
        capabilities = [
          "MAX-MPDU-11454"
          "VHT160"
          "RXLDPC"
          "SHORT-GI-80"
          "SHORT-GI-160"
          "TX-STBC-2BY1"
          "SU-BEAMFORMER"
          "SU-BEAMFORMEE"
          "MU-BEAMFORMER"
          "MU-BEAMFORMEE"
          "RX-ANTENNA-PATTERN"
          "TX-ANTENNA-PATTERN"
        ];
      };
      wifi6 = {
        enable = true;
        operatingChannelWidth = "80";
        singleUserBeamformer = true;
        singleUserBeamformee = true;
        multiUserBeamformer = true;
      };
    };
  };
}
