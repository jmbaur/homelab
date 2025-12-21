{ config, pkgs, ... }:
{
  hardware.firmware = [
    pkgs.wireless-regdb
    (pkgs.extractLinuxFirmwareDirectory "mediatek")
  ];

  hardware.armada-388-clearfog.enable = true;

  # TODO(jared): use FIT_BEST_MATCH feature in u-boot to choose this automatically
  hardware.deviceTree.name = "armada-388-clearfog-pro.dtb";

  custom = {
    server.enable = true;
    basicNetwork.enable = !config.router.enable;
    recovery.targetDisk = "/dev/disk/by-path/platform-f10a8000.sata-ata-1.0";
  };

  # Keep "wlan*" names for mt7915e card
  systemd.network.links."10-mt7915" = {
    matchConfig.Path = "platform-soc:pcie-pci-0000:01:00.0";
    linkConfig.NamePolicy = "kernel";
  };

  # hostapd tuning config for mt7915e
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
          "MAX-MPDU-7991"
          "RXLDPC"
          "SHORT-GI-80"
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
