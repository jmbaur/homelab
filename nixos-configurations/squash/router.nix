{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.kernelParams = [ "cfg80211.ieee80211_regdom=US" ];
  hardware.wirelessRegulatoryDatabase = true;

  services.iperf3 = {
    enable = true;
    openFirewall = false;
  };

  custom.yggdrasil.allKnownPeers.allowedTCPPorts = [ config.services.iperf3.port ];

  router = {
    enable = true;
    lanInterface = config.systemd.network.netdevs."10-br0".netdevConfig.Name;
    wanInterface = "wan";
    dns.upstreamProvider = "quad9";
  };

  # Keep "wlan*" names for mt7915e card
  systemd.network.links."10-mt7915" = {
    matchConfig.Path = "platform-soc:pcie-pci-0000:01:00.0";
    linkConfig.NamePolicy = "kernel";
  };

  systemd.network.netdevs."10-br0".netdevConfig = {
    Name = "br0";
    Kind = "bridge";
  };

  systemd.network.networks = lib.mapAttrs' (name: value: lib.nameValuePair "10-${name}" value) (
    lib.genAttrs
      [
        "lan1"
        "lan2"
        "lan3"
        "lan4"
        "lan5"
        "lan6"
      ]
      (name: {
        inherit name;
        bridge = [ config.router.lanInterface ];
        linkConfig.RequiredForOnline = false;
      })
  );

  environment.systemPackages = [
    pkgs.iw
    pkgs.mac-vendor-lookup
  ];

  sops.secrets = {
    wlan0.reloadUnits = [ config.systemd.services.hostapd.name ];
    wlan1.reloadUnits = [ config.systemd.services.hostapd.name ];
  };

  services.hostapd = {
    enable = true;
    radios.wlan1 = {
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
          # "HT40-"
          "SHORT-GI-20"
          "SHORT-GI-40"
          "TX-STBC"
          "RX-STBC1"
          "MAX-AMSDU-7935"
        ];
      };
      settings.bridge = config.router.lanInterface;
      networks.wlan1 = {
        ssid = "Silence of the LANs";
        authentication = {
          # TODO(jared): investigate using wpa3-sae-transition
          #
          # Allow older devices that only support wpa2 to connect.
          mode = "wpa2-sha256";
          wpaPasswordFile = config.sops.secrets.wlan1.path;
          saePasswordsFile = config.sops.secrets.wlan1.path;
        };
      };
    };
    radios.wlan0 = {
      band = "5g";
      countryCode = "US";
      wifi7.enable = false;
      wifi4 = {
        enable = true;
        capabilities = [
          "RXLDPC"
          "HT40+"
          # "HT40-"
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
      settings.bridge = config.router.lanInterface;
      networks.wlan0 = {
        ssid = "SpiderLAN";
        authentication = {
          mode = "wpa3-sae-transition";
          wpaPasswordFile = config.sops.secrets.wlan0.path;
          saePasswordsFile = config.sops.secrets.wlan0.path;
        };
      };
    };
  };
}
