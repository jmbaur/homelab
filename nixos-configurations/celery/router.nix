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

  custom.ddns = {
    enable = true;
    interface = config.router.wanInterface;
    domain = "jmbaur.com";
  };

  custom.yggdrasil.allKnownPeers.allowedTCPPorts = [ config.services.iperf3.port ];

  networking.firewall = {
    allowedTCPPorts = [ 443 ];
    interfaces.${config.router.lanInterface}.allowedTCPPorts = [ 9001 ];
    extraInputRules = ''
      iifname ${config.router.wanInterface} tcp dport ssh drop
    '';
  };

  services.yggdrasil.settings = {
    Listen = [ "tls://[::]:443" ];
    MulticastInterfaces = [
      {
        Regex = config.router.lanInterface;
        Beacon = true;
        Listen = true;
        Port = 9001;
      }
    ];
  };

  router = {
    enable = true;
    lanInterface = config.systemd.network.netdevs."10-br0".netdevConfig.Name;
    wanInterface = "wan";
    dns.upstreamProvider = "quad9";
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
    radios.wlan0 = {
      settings.bridge = config.router.lanInterface;
      networks.wlan0 = {
        ssid = "Silence of the LANs";
        authentication = {
          # TODO(jared): investigate using wpa3-sae-transition
          #
          # Allow older devices that only support wpa2 to connect.
          mode = "wpa2-sha256";
          wpaPasswordFile = config.sops.secrets.wlan0.path;
          saePasswordsFile = config.sops.secrets.wlan0.path;
        };
      };
    };
    radios.wlan1 = {
      settings.bridge = config.router.lanInterface;
      networks.wlan1 = {
        ssid = "SpiderLAN";
        authentication = {
          mode = "wpa3-sae-transition";
          wpaPasswordFile = config.sops.secrets.wlan1.path;
          saePasswordsFile = config.sops.secrets.wlan1.path;
        };
      };
    };
  };
}
